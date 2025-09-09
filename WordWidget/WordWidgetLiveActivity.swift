//
//  WordWidgetLiveActivity.swift
//  WordWidget
//
//  Created by Lê Nguyễn on 9/9/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WordWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WordWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WordWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WordWidgetAttributes {
    fileprivate static var preview: WordWidgetAttributes {
        WordWidgetAttributes(name: "World")
    }
}

extension WordWidgetAttributes.ContentState {
    fileprivate static var smiley: WordWidgetAttributes.ContentState {
        WordWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WordWidgetAttributes.ContentState {
         WordWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WordWidgetAttributes.preview) {
   WordWidgetLiveActivity()
} contentStates: {
    WordWidgetAttributes.ContentState.smiley
    WordWidgetAttributes.ContentState.starEyes
}
