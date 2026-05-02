import SwiftUI
import SwiftData

// MARK: - DailyWinsView

/// Wins tab — today's entry editor at top, reverse-chronological history below.
/// Per D-09: today's editor always visible; per D-08: history newest-first.
/// Per D-10: "Past Wins" section header, empty state "Your wins will appear here."
struct DailyWinsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel = DailyWinsViewModel()
    @State private var winToDelete: DailyWin?
    @State private var showingDeleteConfirmation = false
    @FocusState private var editorFocused: Bool

    // Reverse-chronological all wins query — history filters out today below (D-08)
    @Query(sort: \DailyWin.date, order: .reverse) private var allWins: [DailyWin]

    // History = all wins except today's entry (D-09 — today's editor shown separately)
    private var historyWins: [DailyWin] {
        allWins.filter { win in
            guard let d = win.date else { return true }
            return !Calendar.current.isDateInToday(d)
        }
    }

    private var todayHeaderText: String {
        Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    var body: some View {
        List {
            // MARK: Today's editor (D-09)
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        // Placeholder overlay (TextEditor has no native placeholder)
                        if viewModel.draftText.isEmpty {
                            Text("What's your win today?")
                                .font(.body).fontDesign(.rounded)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $viewModel.draftText)
                            .font(.body).fontDesign(.rounded)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .focused($editorFocused)
                            .accessibilityLabel("Today's win entry")
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") { editorFocused = false }
                                }
                            }
                    }

                    // Character count (D-04, UI-SPEC)
                    // WR-03: Use sanitized count so the displayed value matches what
                    // saveEntry validates against (avoids "501/500" when whitespace
                    // padding inflates the raw count).
                    Text("\(viewModel.sanitizedCount)/500")
                        .font(.caption).fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .accessibilityLabel("\(viewModel.sanitizedCount) of 500 characters used")

                    // Inline validation error
                    if let error = viewModel.validationError {
                        Text(error.errorDescription ?? "")
                            .font(.caption).fontDesign(.rounded)
                            .foregroundStyle(.red)
                    }

                    // Save Win CTA — warm orange gradient capsule (UI-SPEC accent)
                    Button {
                        do {
                            try viewModel.saveEntry(context: modelContext)
                            editorFocused = false
                        } catch {
                            // validationError is set inside saveEntry — UI picks it up
                        }
                    } label: {
                        Text("Save Win")
                            .font(.headline).fontDesign(.rounded)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.55, blue: 0.27),
                                        Color(red: 0.78, green: 0.48, blue: 0.95)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }
                    .disabled(viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Save win entry")
                    .accessibilityHint(
                        viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? "Enter your win before saving"
                            : "Saves your win for today"
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text(todayHeaderText)
                    .font(.title3.weight(.semibold)).fontDesign(.rounded)
            }
            .listRowBackground(Color(.secondarySystemGroupedBackground))

            // MARK: Past Wins history (D-08, D-10)
            Section {
                if historyWins.isEmpty {
                    Text("Your wins will appear here.")
                        .font(.body).fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .accessibilityLabel("No past wins yet")
                } else {
                    ForEach(historyWins) { win in
                        winRow(for: win)
                    }
                }
            } header: {
                Text("Past Wins")
                    .font(.title3.weight(.semibold)).fontDesign(.rounded)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Daily Wins")
        .navigationBarTitleDisplayMode(.large)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: historyWins.count)
        .onAppear {
            // Pre-fill editor if today's entry exists (GRAT-04, D-09)
            if let existing = viewModel.todayEntry(context: modelContext) {
                viewModel.draftText = existing.text ?? ""
            }
        }
        .confirmationDialog(
            "Delete this win?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let win = winToDelete {
                    // WR-02: If deleting today's entry, also clear the pre-filled
                    // editor draft so a subsequent save does not silently re-insert
                    // the deleted text.
                    if Calendar.current.isDateInToday(win.date ?? .distantPast) {
                        viewModel.draftText = ""
                    }
                    viewModel.delete(win, context: modelContext)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Win Row

    @ViewBuilder
    private func winRow(for win: DailyWin) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(win.date?.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) ?? "")
                .font(.body).fontDesign(.rounded)
                .foregroundStyle(.secondary)
            Text(win.text ?? "")
                .font(.body).fontDesign(.rounded)
                .foregroundStyle(.primary)
                .lineLimit(4)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .listRowBackground(Color(.secondarySystemGroupedBackground))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                winToDelete = win
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete win")
        }
    }
}
