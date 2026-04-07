import WidgetKit
import SwiftUI

@main
struct VitaminGWidgetBundle: WidgetBundle {
    var body: some Widget {
        GoalSummaryWidget()
        StreakWidget()
    }
}
