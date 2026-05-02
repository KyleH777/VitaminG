import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class DailyWinsViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var viewModel: DailyWinsViewModel!

    override func setUp() async throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        viewModel = DailyWinsViewModel()
    }

    override func tearDown() async throws {
        container = nil
        viewModel = nil
    }

    // MARK: - todayEntry tests

    func test_todayEntry_emptyStore_returnsNil() throws {
        let context = ModelContext(container)
        XCTAssertNil(viewModel.todayEntry(context: context))
    }

    func test_todayEntry_winWithTodayDate_returnsWin() throws {
        let context = ModelContext(container)
        let win = DailyWin(date: Date(), text: "Today's win")
        context.insert(win)
        XCTAssertNotNil(viewModel.todayEntry(context: context))
    }

    func test_todayEntry_winWithYesterdayDate_returnsNil() throws {
        let context = ModelContext(container)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let win = DailyWin(date: yesterday, text: "Yesterday's win")
        context.insert(win)
        XCTAssertNil(viewModel.todayEntry(context: context))
    }

    // MARK: - saveEntry validation tests

    func test_saveEntry_emptyText_throwsTextEmpty() {
        let context = ModelContext(container)
        viewModel.draftText = ""
        XCTAssertThrowsError(try viewModel.saveEntry(context: context)) { error in
            XCTAssertEqual(error as? DailyWinValidationError, .textEmpty)
        }
    }

    func test_saveEntry_textTooLong_throwsTextTooLong() {
        let context = ModelContext(container)
        viewModel.draftText = String(repeating: "a", count: 501)
        XCTAssertThrowsError(try viewModel.saveEntry(context: context)) { error in
            XCTAssertEqual(error as? DailyWinValidationError, .textTooLong(500))
        }
    }

    // MARK: - saveEntry insert/update tests

    func test_saveEntry_validText_noExistingEntry_insertsOne() throws {
        let context = ModelContext(container)
        viewModel.draftText = "My first win"
        try viewModel.saveEntry(context: context)
        let all = try context.fetch(FetchDescriptor<DailyWin>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.text, "My first win")
    }

    func test_saveEntry_validText_todayEntryExists_updatesNotInserts() throws {
        let context = ModelContext(container)
        let existing = DailyWin(date: Date(), text: "First save")
        context.insert(existing)

        viewModel.draftText = "Updated win"
        try viewModel.saveEntry(context: context)

        let all = try context.fetch(FetchDescriptor<DailyWin>())
        XCTAssertEqual(all.count, 1, "Should not insert a second entry for today")
        XCTAssertEqual(all.first?.text, "Updated win")
    }

    // MARK: - delete test

    func test_delete_removesWinFromStore() throws {
        let context = ModelContext(container)
        let win = DailyWin(date: Date(), text: "To be deleted")
        context.insert(win)
        viewModel.delete(win, context: context)
        let all = try context.fetch(FetchDescriptor<DailyWin>())
        XCTAssertEqual(all.count, 0)
    }

    // MARK: - NotificationScheduler win notification tests

    func test_winIdentifier_distinctFromDailyReminderIdentifier() {
        XCTAssertNotEqual(
            NotificationScheduler.winIdentifier,
            NotificationScheduler.identifier,
            "Win reminder must have a separate identifier from goal reminder"
        )
    }

    func test_makeWinContent_hasCorrectTitleAndBody() {
        let content = NotificationScheduler.shared.makeWinContent()
        XCTAssertEqual(content.title, "Vitamin G")
        XCTAssertEqual(content.body, "What's your win today?")
        XCTAssertEqual(content.userInfo["deepLink"] as? String, "wins")
    }
}
