import SwiftUI

struct VGTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // AppTab icon mapping — 1:1 with AppTab.allCases order (home/goals/explore/community/profile).
    // D-07: Community and Explore positions swapped; "Me" renamed to "Profile".
    private let tabs: [(label: String, icon: String)] = [
        ("Home",      "house"),
        ("Goals",     "circle.circle"),
        ("Explore",   "magnifyingglass"),
        ("Community", "person.2"),
        ("Profile",   "person"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(zip(AppTab.allCases, tabs)), id: \.0) { tabCase, tab in
                tabItem(tab: tabCase, label: tab.label, icon: tab.icon)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
        .background(
            colorScheme == .dark
                ? Color(red: 0.086, green: 0.067, blue: 0.047).opacity(0.92)
                : VGTheme.warmWhite
        )
        .overlay(alignment: .top) {
            Rectangle().frame(height: 0.5).foregroundStyle(VGTheme.separator)
        }
        .background(.ultraThinMaterial)
    }

    private func tabItem(tab: AppTab, label: String, icon: String) -> some View {
        let isActive = selection == tab
        return Button {
            if reduceMotion {
                selection = tab
            } else {
                withAnimation(.easeInOut(duration: 0.15)) { selection = tab }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 4) {
                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(isActive ? VGTheme.accentTerra : .clear)
                    .shadow(color: isActive ? VGTheme.accentTerra : .clear, radius: 5)

                Image(systemName: isActive ? icon + ".fill" : icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isActive ? VGTheme.accentTerra : VGTheme.textMuted)
                    .shadow(color: isActive && colorScheme == .dark
                            ? VGTheme.accentTerra.opacity(0.55) : .clear, radius: 6)

                Text(label)
                    .font(.caption2.weight(isActive ? .semibold : .regular))
                    .kerning(0.4)
                    .foregroundStyle(isActive ? VGTheme.accentTerra : VGTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
}
