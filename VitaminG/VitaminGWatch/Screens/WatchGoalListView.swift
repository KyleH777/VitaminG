import SwiftUI

// Screen 04 — Today's Goals List
struct WatchGoalListView: View {
    struct GoalItem {
        let title: String
        let progress: Double
        let color: Color
        let sub: String
    }

    private let goals: [GoalItem] = [
        .init(title: "Workout",         progress: 1.0,  color: VGWatch.terraSoft, sub: "Done · 6pm"),
        .init(title: "Water · 8 glasses", progress: 0.62, color: VGWatch.sageBright, sub: "5 of 8"),
        .init(title: "Read 10 pages",   progress: 0.0,  color: VGWatch.gold,     sub: "Pending"),
        .init(title: "Bed by 11pm",     progress: 0.0,  color: VGWatch.plum,     sub: "Pending"),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("4 GOALS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(VGWatch.sageBright)
                        .tracking(2)
                    Text("Today")
                        .font(VGWatch.serif(18))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

                // Goal rows
                VStack(spacing: 5) {
                    ForEach(goals.indices, id: \.self) { i in
                        GoalRow(goal: goals[i])
                    }
                }
                .padding(.horizontal, 10)

                Spacer()
            }
        }
    }
}

private struct GoalRow: View {
    let goal: WatchGoalListView.GoalItem
    private var isDone: Bool { goal.progress >= 1.0 }

    var body: some View {
        HStack(spacing: 8) {
            // Ring or filled check
            if isDone {
                Circle()
                    .fill(goal.color)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                    )
            } else {
                VGRingView(progress: goal.progress, size: 22, lineWidth: 2.5,
                           color: goal.color, trackColor: .white.opacity(0.10), glow: false)
            }

            // Title + status
            VStack(alignment: .leading, spacing: 1) {
                Text(goal.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(goal.sub.uppercased())
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(isDone ? goal.color : .white.opacity(0.40))
                    .tracking(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(isDone ? goal.color.opacity(0.15) : Color.white.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(isDone ? goal.color.opacity(0.44) : Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(14)
    }
}

#Preview {
    WatchGoalListView()
}
