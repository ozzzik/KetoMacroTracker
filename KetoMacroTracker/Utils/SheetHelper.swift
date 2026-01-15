//
//  SheetHelper.swift
//  Keto Macro Tracker
//
//  Helper to present sheets as fullScreenCover on iPad, sheet on iPhone
//

import SwiftUI

extension View {
    /// Presents a sheet that appears as fullScreenCover on iPad, sheet on iPhone
    func adaptiveSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.fullScreenCover(isPresented: isPresented) {
                    content()
                }
            } else {
                self.sheet(isPresented: isPresented) {
                    content()
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    /// Presents a sheet with item binding, adaptive for iPad/iPhone
    func adaptiveSheet<Item: Identifiable, Content: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.fullScreenCover(item: item) { item in
                    content(item)
                }
            } else {
                self.sheet(item: item) { item in
                    content(item)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
}

