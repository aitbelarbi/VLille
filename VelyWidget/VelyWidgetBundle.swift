import WidgetKit
import SwiftUI

@main
struct VelyWidgetBundle: WidgetBundle {
    var body: some Widget {
        VelyWidget()
        VelyWidgetLiveActivity()
    }
}
