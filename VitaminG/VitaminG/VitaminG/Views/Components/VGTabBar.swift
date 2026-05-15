import SwiftUI

struct VGTabBar: View {
    @Binding var selection: Int
    @Environment(\.colorScheme) private var colorScheme

    private let tabs: [(label: String, icon: String)] = [
        ("Home",      "house"),
        ("Goals",     "circle.circle"),
        ("Community", "person.2"),
        ("Explore",   "magnifyingglass"),
        ("Me",        "person"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                tabItem(index: index, label: tab.label, icon: tab.icon)
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

    private func tabItem(index: Int, label: String, icon: String) -> some View {
        let isActive = selection == index
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selection = index }
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
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                    .kerning(0.4)
                    .foregroundStyle(isActive ? VGTheme.accentTerra : VGTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
    }
}
