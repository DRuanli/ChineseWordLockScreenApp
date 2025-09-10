//
//  WordWidgetBundle.swift
//  WordWidget
//
//  Fixed widget bundle without conflicts
//

import WidgetKit
import SwiftUI

@main
struct WordWidgetBundle: WidgetBundle {
    var body: some Widget {
        WordWidget()
        ProgressWidget()
    }
}
