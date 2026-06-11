import SwiftUI

struct LocalComment: Codable, Identifiable {
    let id: UUID
    let authorName: String
    let body: String
    let createdAt: Date

    init(authorName: String, body: String) {
        self.id = UUID()
        self.authorName = authorName
        self.body = body
        self.createdAt = Date()
    }
}

struct CommentSheetView: View {
    let postID: String
    @AppStorage("vg_onboardingName") private var userName: String = ""
    @State private var comments: [LocalComment] = []
    @State private var draftText = ""
    @State private var positivityRejected = false
    @FocusState private var fieldFocused: Bool

    private var storageKey: String { "vg_comments_\(postID)" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if comments.isEmpty {
                    Spacer()
                    Text("No comments yet.\nBe the first to encourage.")
                        .font(.system(size: 14)).foregroundStyle(VGTheme.textMuted)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(comments) { c in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(c.authorName.isEmpty ? "You" : c.authorName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(VGTheme.textPrimary)
                                    Text(c.body).font(.system(size: 14))
                                        .foregroundStyle(VGTheme.textSecondary)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(VGTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 12)
                    }
                }

                Divider()
                VStack(spacing: 4) {
                    if positivityRejected {
                        Text("Only encouraging comments are allowed here. 🌱")
                            .font(.system(size: 12))
                            .foregroundStyle(VGTheme.accentTerra)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                    }
                    HStack(spacing: 10) {
                        TextField("Say something encouraging…", text: $draftText, axis: .vertical)
                            .font(.system(size: 14))
                            .lineLimit(1...4)
                            .focused($fieldFocused)
                            .onChange(of: draftText) { _, _ in positivityRejected = false }
                        Button {
                            let body = draftText.trimmingCharacters(in: .whitespaces)
                            guard !body.isEmpty else { return }
                            guard PositivityFilter.isAllowed(body) else {
                                positivityRejected = true
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                                return
                            }
                            let c = LocalComment(authorName: userName, body: String(body.prefix(300)))
                            comments.append(c)
                            persist()
                            draftText = ""
                            positivityRejected = false
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(draftText.isEmpty ? VGTheme.textMuted : VGTheme.accentTerra)
                        }
                        .disabled(draftText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .background(VGTheme.background)
            }
            .background(VGTheme.background)
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { load(); fieldFocused = true }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(comments) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([LocalComment].self, from: data)
        else { return }
        comments = saved
    }
}
