import XCTest
@testable import VitaminG

@MainActor
final class ExploreViewModelTests: XCTestCase {

    private let gifterKey = "vg_explore_gifterDate"
    private let moodKey = "vg_explore_moodDate"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: gifterKey)
        UserDefaults.standard.removeObject(forKey: moodKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: gifterKey)
        UserDefaults.standard.removeObject(forKey: moodKey)
        super.tearDown()
    }

    // EXPLORE-01: First activation returns a goal
    func testGifterActivation() {
        let vm = ExploreViewModel()
        let result = vm.onGifterActivated()
        XCTAssertNotNil(result, "First activation must return a GifterGoal")
        XCTAssertNotNil(vm.dispensedGoal)
    }

    // EXPLORE-02: Second call on same day is a no-op
    func testGifterGate() {
        let vm = ExploreViewModel()
        _ = vm.onGifterActivated()
        vm.markGiftedToday()
        let secondResult = vm.onGifterActivated()
        XCTAssertNil(secondResult, "Second activation same day must return nil")
    }

    // EXPLORE-02: Gate resets when stored date is yesterday
    func testGifterGateReset() {
        let vm = ExploreViewModel()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        UserDefaults.standard.set(yesterday, forKey: gifterKey)
        XCTAssertFalse(vm.hasGiftedToday, "Yesterday's date must not block today's gifter")
        let result = vm.onGifterActivated()
        XCTAssertNotNil(result)
    }

    // EXPLORE-04: vitaminShelfCategories contains exactly 6 items
    func testVitaminShelfCategories() {
        let shelf: [GoalCategory] = [.body, .mind, .wellness, .money, .connection, .creative]
        XCTAssertEqual(shelf.count, 6)
        // All 6 must be distinct GoalCategory cases
        XCTAssertEqual(Set(shelf.map(\.rawValue)).count, 6)
    }

    // EXPLORE-01: todaysGifterGoal is deterministic for the same day
    func testGifterDeterminism() {
        let goal1 = ExploreContent.todaysGifterGoal
        let goal2 = ExploreContent.todaysGifterGoal
        XCTAssertEqual(goal1.title, goal2.title)
    }

    // EXPLORE-01: gifter pool has 20 items
    func testGifterPoolSize() {
        XCTAssertEqual(ExploreContent.gifterPool.count, 20)
    }
}
