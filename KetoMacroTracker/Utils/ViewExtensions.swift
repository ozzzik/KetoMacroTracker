//
//  ViewExtensions.swift
//  Keto Macro Tracker
//
//  Helper extensions for consistent view presentation
//

import SwiftUI

extension View {
    /// Presents a sheet with iPad-optimized presentation (full screen cover on iPad, sheet on iPhone)
    func ipadOptimizedSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
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
    
    /// Presents a sheet with item binding, iPad-optimized
    func ipadOptimizedSheet<Item: Identifiable, Content: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
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

