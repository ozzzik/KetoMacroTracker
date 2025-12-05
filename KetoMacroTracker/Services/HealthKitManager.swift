//
//  HealthKitManager.swift
//  Keto Macro Tracker
//
//  Apple Health integration for reading weight and writing nutrition data
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized = false
    @Published var lastWeight: Double? = nil
    @Published var lastWeightDate: Date? = nil
    
    private let healthStore = HKHealthStore()
    
    // Types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
        HKObjectType.quantityType(forIdentifier: .leanBodyMass)!
    ]
    
    // Types we want to write
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
        HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
        HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
        HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        HKObjectType.quantityType(forIdentifier: .dietaryWater)!
    ]
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit is not available on this device")
            return
        }
        
        let allTypes = readTypes.union(writeTypes)
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    print("✅ HealthKit authorization granted")
                    self?.loadLatestWeight()
                } else {
                    self?.isAuthorized = false
                    print("❌ HealthKit authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        // Check if we have authorization for at least one type
        // Note: authorizationStatus is only available after requesting authorization
        // So we'll check on first request instead
        DispatchQueue.main.async {
            // Default to false, will be set after authorization request
            self.isAuthorized = false
        }
    }
    
    // MARK: - Read Weight
    
    func loadLatestWeight() {
        guard isAuthorized else { return }
        
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] query, samples, error in
            guard let samples = samples as? [HKQuantitySample],
                  let latestSample = samples.first else {
                return
            }
            
            let weightInKg = latestSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            let weightInLbs = weightInKg * 2.20462 // Convert to pounds
            
            DispatchQueue.main.async {
                self?.lastWeight = weightInLbs
                self?.lastWeightDate = latestSample.endDate
                print("📊 Loaded weight from Health: \(String(format: "%.1f", weightInLbs)) lbs")
            }
        }
        
        healthStore.execute(query)
    }
    
    func syncWeightToProfile() {
        guard let weight = lastWeight else { return }
        
        let profileManager = ProfileManager.shared
        profileManager.updateProfile(
            weight: weight,
            height: profileManager.profile.height,
            age: profileManager.profile.age,
            gender: profileManager.profile.gender,
            activityLevel: profileManager.profile.activityLevel,
            goal: profileManager.profile.goal
        )
        
        print("✅ Synced weight from Health to profile: \(String(format: "%.1f", weight)) lbs")
    }
    
    // MARK: - Write Nutrition Data
    
    func saveNutritionToHealth(protein: Double, carbs: Double, fat: Double, calories: Double, date: Date = Date()) {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        // Delete existing samples for this day first
        deleteNutritionForDate(date)
        
        // Save protein
        if let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let proteinQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: protein)
            let proteinSample = HKQuantitySample(
                type: proteinType,
                quantity: proteinQuantity,
                start: startDate,
                end: endDate
            )
            healthStore.save(proteinSample) { success, error in
                if success {
                    print("✅ Saved protein to Health: \(protein)g")
                }
            }
        }
        
        // Save carbs
        if let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let carbsQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: carbs)
            let carbsSample = HKQuantitySample(
                type: carbsType,
                quantity: carbsQuantity,
                start: startDate,
                end: endDate
            )
            healthStore.save(carbsSample) { success, error in
                if success {
                    print("✅ Saved carbs to Health: \(carbs)g")
                }
            }
        }
        
        // Save fat
        if let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            let fatQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: fat)
            let fatSample = HKQuantitySample(
                type: fatType,
                quantity: fatQuantity,
                start: startDate,
                end: endDate
            )
            healthStore.save(fatSample) { success, error in
                if success {
                    print("✅ Saved fat to Health: \(fat)g")
                }
            }
        }
        
        // Save calories
        if let caloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
            let caloriesSample = HKQuantitySample(
                type: caloriesType,
                quantity: caloriesQuantity,
                start: startDate,
                end: endDate
            )
            healthStore.save(caloriesSample) { success, error in
                if success {
                    print("✅ Saved calories to Health: \(calories) kcal")
                }
            }
        }
    }
    
    func saveWaterToHealth(amount: Double, unit: HKUnit = HKUnit.fluidOunceUS(), date: Date = Date()) {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        if let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            let waterQuantity = HKQuantity(unit: unit, doubleValue: amount)
            let waterSample = HKQuantitySample(
                type: waterType,
                quantity: waterQuantity,
                start: startDate,
                end: endDate
            )
            healthStore.save(waterSample) { success, error in
                if success {
                    print("✅ Saved water to Health: \(amount) \(unit.unitString)")
                }
            }
        }
    }
    
    // Note: Fasting is not a standard HealthKit category
    // We can track it in the app but can't sync to Health
    func saveFastingSession(startDate: Date, endDate: Date) {
        // Fasting tracking is kept in-app only
        // HealthKit doesn't have a standard fasting category
        print("ℹ️ Fasting sessions are tracked in-app only (not available in HealthKit)")
    }
    
    private func deleteNutritionForDate(_ date: Date) {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        for type in writeTypes {
            if let quantityType = type as? HKQuantityType {
                let deleteQuery = HKAnchoredObjectQuery(
                    type: quantityType,
                    predicate: predicate,
                    anchor: nil,
                    limit: HKObjectQueryNoLimit
                ) { query, samples, deletedObjects, anchor, error in
                    guard let samples = samples else { return }
                    
                    self.healthStore.delete(samples) { success, error in
                        if success {
                            print("🗑️ Deleted existing Health data for \(date)")
                        }
                    }
                }
                healthStore.execute(deleteQuery)
            }
        }
    }
}

