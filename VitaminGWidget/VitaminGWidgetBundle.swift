import WidgetKit
import SwiftUI

// Phase 1: Widget target stub — scaffolded for App Group entitlement.
// Widget UI and AppIntentConfiguration will be added in Phase 4.
// This target exists so the App Group entitlement is configured before any data is persisted (D-06).

@main
struct VitaminGWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Phase 4 will add widget implementations here
        VitaminGWidgetPlaceholder()
    }
}

// Minimal placeholder widget to satisfy WidgetBundle requirement
struct VitaminGWidgetPlaceholder: Widget {
    let kind: String = "VitaminGWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { _ in
            Text("Vitamin G")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Vitamin G")
        .description("Your daily goals at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) { completion(SimpleEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: .now)], policy: .atEnd))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}
