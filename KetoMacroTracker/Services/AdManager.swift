//
//  AdManager.swift
//  KetoMacroTracker
//
//  Manages ads: interstitials after food logs and on app open; rewarded ad for ad-free rest of day.
//

import Foundation
import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Manages ads: interstitials after usage, and optional rewarded ad whose reward is "ad-free for the rest of the day".
@MainActor
final class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    /// Rewarded Interstitial: "watch ad for ad-free rest of day".
    private let rewardedInterstitialAdUnitID = "ca-app-pub-4048960606079471/4515444862"
    /// Interstitial: pop-up every N food logs.
    private let interstitialAdUnitID = "ca-app-pub-4048960606079471/8251364106"

    private let foodLogsBeforeInterstitial = 5 // Food logs + searches combined
    private let adFreeRewardDateKey = "KetoAdFreeRewardDate"
    private let foodLogCountKey = "KetoFoodLogCountSinceLastInterstitial"
    private let minutesBeforeAppOpenInterstitial = 5
    private let lastAppOpenInterstitialTimeKey = "KetoLastAppOpenInterstitialTime"

    @Published private(set) var isAdReady = false
    @Published private(set) var isLoading = false
    @Published private(set) var isAdFreeForRestOfDay = false

    var onReward: (() -> Void)?

    #if canImport(GoogleMobileAds)
    private var rewardedInterstitialAd: RewardedInterstitialAd?
    private var interstitialAd: InterstitialAd?
    private var isLoadingInterstitial = false
    private var pendingShowInterstitial = false
    private var nextInterstitialIsAppOpen = false
    #endif

    private override init() {
        super.init()
        updateAdFreeState()
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("FoodLogged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleFoodLogged()
            }
        }
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SearchPerformed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleActionCounted()
            }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.tryShowAppOpenInterstitialIfNeeded()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func grantAdFreeForRestOfDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        UserDefaults.standard.set(today, forKey: adFreeRewardDateKey)
        updateAdFreeState()
    }

    private func updateAdFreeState() {
        let calendar = Calendar.current
        guard let date = UserDefaults.standard.object(forKey: adFreeRewardDateKey) as? Date else {
            isAdFreeForRestOfDay = false
            return
        }
        isAdFreeForRestOfDay = calendar.isDateInToday(date)
    }

    func start() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: { _ in })
        updateAdFreeState()
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await loadRewardedInterstitial()
            await loadInterstitial()
            // Trigger app-open interstitial on first launch (after ads loaded)
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay so user sees app first
            tryShowAppOpenInterstitialIfNeeded()
        }
        #endif
    }

    func loadRewardedInterstitial() async {
        #if canImport(GoogleMobileAds)
        guard !isLoading else { return }
        isLoading = true
        isAdReady = false
        defer { isLoading = false }
        do {
            rewardedInterstitialAd = try await RewardedInterstitialAd.load(
                with: rewardedInterstitialAdUnitID,
                request: Request()
            )
            rewardedInterstitialAd?.fullScreenContentDelegate = self
            isAdReady = true
        } catch {
            print("AdMob: Rewarded interstitial failed to load: \(error.localizedDescription)")
        }
        #endif
    }

    func showRewardedInterstitial(from windowScene: UIWindowScene?) {
        #if canImport(GoogleMobileAds)
        guard let ad = rewardedInterstitialAd else {
            Task { await loadRewardedInterstitial() }
            return
        }
        let rootVC = windowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? windowScene?.windows.first?.rootViewController
            ?? rootViewControllerForAds()
        guard let vc = rootVC else { return }
        do {
            try ad.canPresent(from: vc)
        } catch {
            return
        }
        ad.present(from: vc, userDidEarnRewardHandler: { [weak self] in
            self?.onReward?()
            self?.rewardedInterstitialAd = nil
            self?.isAdReady = false
            Task { await self?.loadRewardedInterstitial() }
        })
        #endif
    }

    private func tryShowAppOpenInterstitialIfNeeded() {
        updateAdFreeState()
        if isAdFreeForRestOfDay { return }
        let last = UserDefaults.standard.double(forKey: lastAppOpenInterstitialTimeKey)
        let now = Date().timeIntervalSince1970
        let elapsedMinutes = (now - last) / 60.0
        if last > 0 && elapsedMinutes < Double(minutesBeforeAppOpenInterstitial) {
            print("📺 Ad: App-open skipped (too soon: \(String(format: "%.1f", elapsedMinutes))min)")
            return
        }
        #if canImport(GoogleMobileAds)
        print("📺 Ad: Triggering app-open interstitial")
        nextInterstitialIsAppOpen = true
        tryShowInterstitial()
        #endif
    }

    private func handleFoodLogged() {
        handleActionCounted(delayForSheetDismiss: true)
    }

    private func handleActionCounted(delayForSheetDismiss: Bool = false) {
        updateAdFreeState()
        if isAdFreeForRestOfDay {
            print("📺 Ad: Skipping (ad-free for rest of day)")
            return
        }
        let count = UserDefaults.standard.integer(forKey: foodLogCountKey) + 1
        UserDefaults.standard.set(count, forKey: foodLogCountKey)
        print("📺 Ad: Action counted (food/search), count=\(count)/\(foodLogsBeforeInterstitial)")
        if count >= foodLogsBeforeInterstitial {
            UserDefaults.standard.set(0, forKey: foodLogCountKey)
            if delayForSheetDismiss {
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s for sheet to dismiss
                    tryShowInterstitial()
                }
            } else {
                tryShowInterstitial()
            }
        }
    }

    private func tryShowInterstitial() {
        #if canImport(GoogleMobileAds)
        let vc = rootViewControllerForAds()
        if let ad = interstitialAd, let vc = vc {
            print("📺 Ad: Presenting interstitial")
            ad.present(from: vc)
            interstitialAd = nil
            pendingShowInterstitial = false
            Task { await loadInterstitial() }
            return
        }
        print("📺 Ad: Interstitial not ready (ad=\(interstitialAd != nil), vc=\(vc != nil)) – will show when loaded")
        pendingShowInterstitial = true
        Task { await loadInterstitial() }
        #endif
    }

    /// Returns the topmost view controller (handles sheets/modals) so ads can present correctly.
    private func rootViewControllerForAds() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first else {
            print("📺 Ad: No window found")
            return nil
        }
        guard var vc = window.rootViewController else {
            print("📺 Ad: No root VC")
            return nil
        }
        while let presented = vc.presentedViewController {
            vc = presented
        }
        return vc
    }

    func loadInterstitial() async {
        #if canImport(GoogleMobileAds)
        guard !isLoadingInterstitial else { return }
        isLoadingInterstitial = true
        defer { isLoadingInterstitial = false }
        do {
            interstitialAd = try await InterstitialAd.load(
                with: interstitialAdUnitID,
                request: Request()
            )
            interstitialAd?.fullScreenContentDelegate = self
            print("📺 Ad: Interstitial loaded")
            if pendingShowInterstitial, let ad = interstitialAd, let vc = rootViewControllerForAds() {
                print("📺 Ad: Presenting interstitial (was pending)")
                pendingShowInterstitial = false
                ad.present(from: vc)
                interstitialAd = nil
                await loadInterstitial()
            }
        } catch {
            print("📺 AdMob: Interstitial failed to load: \(error.localizedDescription)")
        }
        #endif
    }
}

#if canImport(GoogleMobileAds)
extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            if nextInterstitialIsAppOpen {
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastAppOpenInterstitialTimeKey)
                nextInterstitialIsAppOpen = false
            }
            rewardedInterstitialAd = nil
            interstitialAd = nil
            isAdReady = false
            await loadRewardedInterstitial()
            await loadInterstitial()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("📺 Ad: Failed to present - \(error.localizedDescription)")
        Task { @MainActor in
            rewardedInterstitialAd = nil
            interstitialAd = nil
            isAdReady = false
            await loadRewardedInterstitial()
            await loadInterstitial()
        }
    }
}
#endif
