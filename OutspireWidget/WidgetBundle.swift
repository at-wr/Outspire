//
//  WidgetBundle.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import SwiftUI
import WidgetKit

@main
struct OutspireWidgetBundle: WidgetBundle {
    var body: some Widget {
        OutspireWidget()
        OutspireWidgetControl()
        CurrentNextClassWidget()
        #if !targetEnvironment(macCatalyst)
            OutspireWidgetLiveActivity()
        #endif
    }
}
