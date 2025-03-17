//
//  OutspireWidgetBundle.swift
//  OutspireWidget
//
//  Created by Alan Ye on 3/17/25.
//

import WidgetKit
import SwiftUI

@main
struct OutspireWidgetBundle: WidgetBundle {
    var body: some Widget {
        OutspireWidget()
        OutspireWidgetControl()
        CurrentNextClassWidget()
        OutspireWidgetLiveActivity()
    }
}
