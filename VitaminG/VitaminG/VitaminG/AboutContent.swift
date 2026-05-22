import Foundation

// MARK: - AboutContent
// Verbatim founder bio and app metadata constants (Plan 19-04, D-03).
// D-03: founderBio must be stored and displayed exactly as provided — no edits.

enum AboutContent {

    static let appName = "Vitamin G"

    // D-03: The following text is the verbatim founder bio provided by the developer.
    // Do not edit, reformat, paraphrase, or omit any words.
    static let founderBio: String = """
        I was diagnosed with testicular cancer and given a new perspective on life overnight.

        At my worst, a mass the size of a softball was pressing against my heart and lungs. Breathing hurt. Moving hurt. But I still made a goal every single day: walk the hospital halls at least once, and climb the stairs to the very top floor. Those small wins kept me grounded when everything else felt out of my control.

        The day I rang the bell, my body proved it still had fight in it.

        After that, I wanted to do things I simply could not do before. Running a 5k was one of them. Not some big symbolic statement — just a goal that was out of reach when I was sick, and now it wasn't.

        That experience taught me something I can't unlearn. Goals do not have to be big to matter. They just have to be yours. Gratitude works the same way. You find it in the small things, or you miss it entirely.

        Vitamin G was built on that belief. Whether you are chasing a personal record or just trying to get out of bed and move today, this is a place to set your goal, show up, and appreciate how far you have already come.
        """

    static var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "Version \(version) (\(build))"
    }
}
