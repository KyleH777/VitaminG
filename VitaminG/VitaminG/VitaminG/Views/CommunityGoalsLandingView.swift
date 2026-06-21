import SwiftUI
import SwiftData
import PhotosUI
import CloudKit

struct CommunityGoalsLandingView: View {
    let userChallenge: UserChallenge

    @State private var showingPhotoPicker = false
    @State private var selectedCheckInPhoto: PhotosPickerItem? = nil
    @State private var isPostingPhoto = false
    @State private var postPhotoError: String? = nil

    private var template: ChallengeTemplate? { userChallenge.template }
    private var accentColor: Color { Color(hex: template?.accentColorHex ?? "#C4673A") }
    private var collectiveProgress: Double {
        min(1.0, Double(userChallenge.totalCheckIns) / Double(max(1, template?.durationDays ?? 90)))
    }
    private var currentDay: Int {
        let start = userChallenge.startDate ?? Date()
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(1, days + 1)
    }
    private var daysLeft: Int {
        max(0, (template?.durationDays ?? 90) - currentDay)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(template?.title ?? "Challenge")")
                            .font(VGTheme.serif(22))
                            .foregroundStyle(VGTheme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text("We're \(Int(collectiveProgress * 100))% of the way there.")
                            .font(VGTheme.serif(18))
                            .foregroundStyle(VGTheme.textPrimary)
                        Text("\(template?.communitySize ?? 0) members")
                            .font(.callout)
                            .foregroundStyle(VGTheme.textMuted)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Collective progress card
                    VStack(spacing: 16) {
                        ProgressRingView(
                            progress: collectiveProgress,
                            tier: .longTerm,
                            isCompleted: false,
                            size: 200,
                            strokeWidth: 12,
                            glow: true
                        )
                        HStack(spacing: 0) {
                            ForEach([
                                ("\(template?.communitySize ?? 0)", "Joined"),
                                ("\(currentDay)", "Day"),
                                ("\(daysLeft)", "Days Left")
                            ], id: \.1) { val, label in
                                VStack(spacing: 4) {
                                    Text(val)
                                        .font(VGTheme.serif(22))
                                        .foregroundStyle(VGTheme.terra)
                                    Text(label)
                                        .font(.caption2)
                                        .foregroundStyle(VGTheme.muted)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(20)
                    .background(VGTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Photo wall
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's check-ins")
                            .font(.callout.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundStyle(VGTheme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [VGTheme.accentTerra.opacity(0.2), VGTheme.accentTerra.opacity(0.05)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .overlay(Text("📸").font(.largeTitle).opacity(0.4).accessibilityHidden(true))
                            .accessibilityHidden(true)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<4) { _ in
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(VGTheme.sandMid)
                                        .frame(width: 90, height: 90)
                                        .accessibilityHidden(true)
                                }
                                Button { showingPhotoPicker = true } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(VGTheme.surface)
                                            .frame(width: 90, height: 90)
                                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(VGTheme.separator, lineWidth: 1))
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundStyle(VGTheme.accentTerra)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Share a check-in photo")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Live ticker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live activity")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(VGTheme.textMuted)
                            .padding(.horizontal, 16)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(["Alex just checked in 🔥", "Sam hit day 7! 🎉", "Jordan logged a workout 💪"], id: \.self) { msg in
                            Text(msg)
                                .font(.callout).fontDesign(.rounded)
                                .foregroundStyle(VGTheme.textPrimary)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(VGTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 16)

                    // Leaderboard
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Leading the pack")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(VGTheme.textMuted)
                            .padding(.horizontal, 16)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(Array(["You", "Member B", "Member C"].enumerated()), id: \.offset) { i, name in
                            HStack(spacing: 12) {
                                Text("\(i + 1)").font(VGTheme.serif(16)).foregroundStyle(VGTheme.muted).frame(width: 20).accessibilityHidden(true)
                                Text(name).font(.callout).fontDesign(.rounded).foregroundStyle(VGTheme.textPrimary)
                                Spacer()
                                Text("\(max(0, userChallenge.totalCheckIns - (i * 2))) check-ins")
                                    .font(.caption).foregroundStyle(VGTheme.textMuted)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(VGTheme.surface).clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(.top, 16)

                    Spacer(minLength: 90)
                }
            }

            // Sticky share CTA
            VStack(spacing: 0) {
                Divider()
                Button { showingPhotoPicker = true } label: {
                    HStack(spacing: 8) {
                        if isPostingPhoto { ProgressView().tint(.white) }
                        else { Image(systemName: "camera.fill").foregroundStyle(.white).accessibilityHidden(true) }
                        Text("Share today's check-in")
                            .font(.body.weight(.semibold)).foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44).padding(.vertical, 16)
                    .background(VGTheme.accentTerra)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20).padding(.vertical, 12)
                }
                .accessibilityLabel("Share today's check-in")
                .background(VGTheme.background)
            }
        }
        .navigationTitle(template?.title ?? "Community Goal")
        .navigationBarTitleDisplayMode(.inline)
        .background(VGTheme.background)
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedCheckInPhoto, matching: .images)
        .onChange(of: selectedCheckInPhoto) { _, item in
            Task { await handleCheckInPhotoSelection(item) }
        }
    }

    private func handleCheckInPhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        isPostingPhoto = true
        do {
            _ = try await CommunityService.postCheckInPhoto(data, challengeCategory: template?.category ?? "general")
        } catch {
            postPhotoError = error.localizedDescription
        }
        isPostingPhoto = false
        selectedCheckInPhoto = nil
    }
}
