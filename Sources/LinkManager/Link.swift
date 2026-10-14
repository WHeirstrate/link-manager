import AppKit

struct Link: Identifiable, Codable, Equatable {
    var id = UUID()
    var title = ""
    var target = ""
}

/// What a link's target string points at.
enum Resolved {
    case web(URL)      // http / https
    case other(URL)    // mailto:, slack://, file paths, apps, ...
    case file(URL)     // local file, folder or .app
}

enum TargetResolver {
    private static let appFolders = [
        "/Applications", "/System/Applications", "/Applications/Utilities",
        "/System/Applications/Utilities", NSHomeDirectory() + "/Applications",
    ]

    static func resolve(_ raw: String) -> Resolved? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        // Local path
        if s.hasPrefix("/") || s.hasPrefix("~") {
            let path = (s as NSString).expandingTildeInPath
            return .file(URL(fileURLWithPath: path))
        }

        // Explicit scheme (https://, slack://, mailto:, tel: ...)
        if s.contains("://") || s.hasPrefix("mailto:") || s.hasPrefix("tel:"),
           let url = URL(string: s) {
            return url.scheme == "http" || url.scheme == "https" ? .web(url) : .other(url)
        }

        // Bundle identifier, e.g. com.apple.Safari
        if !s.contains(" "), s.split(separator: ".").count >= 3,
           let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: s) {
            return .file(app)
        }

        // App name, e.g. "Notes" or "Visual Studio Code"
        let name = s.hasSuffix(".app") ? String(s.dropLast(4)) : s
        for folder in appFolders {
            let candidate = URL(fileURLWithPath: folder).appendingPathComponent(name + ".app")
            if FileManager.default.fileExists(atPath: candidate.path) { return .file(candidate) }
        }

        // Bare domain, e.g. github.com/foo
        if !s.contains(" "), s.contains("."), let url = URL(string: "https://" + s) {
            return .web(url)
        }
        return nil
    }

    static func open(_ raw: String) {
        switch resolve(raw) {
        case .web(let url), .other(let url): NSWorkspace.shared.open(url)
        case .file(let url): NSWorkspace.shared.open(url)
        case nil: NSSound.beep()
        }
    }
}
