//
//  KetoMacroWidgetBundle.swift
//  Keto Macro Tracker
//
//  Widget bundle for all widgets
//
//  NOTE: This file should be in a separate Widget Extension target.
//  To set up widgets:
//  1. In Xcode: File > New > Target > Widget Extension
//  2. Move this file and KetoMacroWidget.swift to the widget extension target
//  3. Add @main to this struct (remove it from KetoMacroTrackerApp.swift in widget target)
//  4. Configure App Group: "group.com.whio.KetoMacroTracker" in both app and widget targets
//

import WidgetKit
import SwiftUI

// @main - Uncomment this when widget is in separate target
struct KetoMacroWidgetBundle: WidgetBundle {
    var body: some Widget {
        KetoMacroWidget()
    }
}

