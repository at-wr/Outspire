//
//  AppIntent.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import WidgetKit
import AppIntents

// Base configuration for class widgets
struct ClassWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Class Widget Configuration" }
    static var description: IntentDescription { "Configure your class widget display." }

    // Configuration for showing countdown
    @Parameter(title: "Show Countdown", default: true)
    var showCountdown: Bool
}

// Configuration for current and next class widget
struct CurrentNextClassWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Current & Next Class Configuration" }
    static var description: IntentDescription { "Configure your current and next class widget display." }

    // Configuration for showing class details
    @Parameter(title: "Show Class Details", default: true)
    var showClassDetails: Bool
}

// Configuration for class table widget
struct ClassTableWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Class Table Configuration" }
    static var description: IntentDescription { "Configure your class table widget display." }

    // Configuration for maximum classes to show
    @Parameter(title: "Max Classes to Show", default: 3)
    var maxClassesToShow: Int
    
    // Configuration for showing class details
    @Parameter(title: "Show Class Details", default: true)
    var showClassDetails: Bool
}
