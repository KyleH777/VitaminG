import SwiftUI

// Root navigation for the Vitamin G watchOS app.
// Uses a vertical page-style TabView (the watchOS default).
struct VGWatchContentView: View {
    var body: some View {
        TabView {
            TodayGlanceView()
                .tag(0)
            WatchGoalListView()
                .tag(1)
            CommunityGlanceView()
                .tag(2)
            WatchFaceView()
                .tag(3)
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    VGWatchContentView()
}
