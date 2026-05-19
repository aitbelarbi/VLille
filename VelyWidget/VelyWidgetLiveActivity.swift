//
//  VelyWidgetLiveActivity.swift
//  VelyWidget
//
//  Created by BADI Maria on 18/05/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct VelyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct VelyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VelyWidgetAttributes.self) { context in
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

extension VelyWidgetAttributes {
    fileprivate static var preview: VelyWidgetAttributes {
        VelyWidgetAttributes(name: "World")
    }
}

extension VelyWidgetAttributes.ContentState {
    fileprivate static var smiley: VelyWidgetAttributes.ContentState {
        VelyWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: VelyWidgetAttributes.ContentState {
         VelyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: VelyWidgetAttributes.preview) {
   VelyWidgetLiveActivity()
} contentStates: {
    VelyWidgetAttributes.ContentState.smiley
    VelyWidgetAttributes.ContentState.starEyes
}
