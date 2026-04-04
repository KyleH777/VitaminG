import SwiftUI
import SwiftData

@main
struct VitaminGApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainerFactory.makeContainer()

            #if DEBUG
            ModelContainerFactory.initializeCloudKitSchema(container: container)
            #endif
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(AppRouter())
        }
    }
}
