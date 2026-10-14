import AppKit

enum FaviconService {
    private static var dir: URL {
        let d = LinkStore.supportDir.appendingPathComponent("icons", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    private static func file(host: String) -> URL {
        dir.appendingPathComponent(host.replacingOccurrences(of: "/", with: "_") + ".png")
    }

    static func cached(host: String) -> NSImage? {
        NSImage(contentsOf: file(host: host))
    }

    /// Downloads the page, finds its icon links and stores the first one that decodes.
    static func fetch(for pageURL: URL) async {
        guard let host = pageURL.host else { return }
        var candidates: [(score: Int, url: URL)] = []

        if let html = await download(pageURL).map({ String(decoding: $0.prefix(400_000), as: UTF8.self) }) {
            for tag in matches(#"<link\b[^>]*>"#, in: html) {
                guard let rel = attribute("rel", in: tag)?.lowercased(), rel.contains("icon"),
                      let href = attribute("href", in: tag),
                      let url = URL(string: href, relativeTo: pageURL)?.absoluteURL else { continue }
                var score = 1
                if rel.contains("apple-touch-icon") { score = 3 }
                else if href.lowercased().hasSuffix(".svg") { score = 0 }  // NSImage can't always render SVG
                else if href.lowercased().contains(".png") { score = 2 }
                candidates.append((score, url))
            }
        }
        candidates.sort { $0.score > $1.score }
        var urls = candidates.map(\.url)
        if let fallback = URL(string: "/favicon.ico", relativeTo: pageURL)?.absoluteURL { urls.append(fallback) }

        for url in urls.prefix(6) {
            guard let data = await download(url), let image = NSImage(data: data),
                  let png = pngData(from: image, side: 64) else { continue }
            try? png.write(to: file(host: host), options: .atomic)
            return
        }
    }

    private static func download(_ url: URL) async -> Data? {
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
                         forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else { return nil }
        return data
    }

    private static func matches(_ pattern: String, in text: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return re.matches(in: text, range: range).compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }

    private static func attribute(_ name: String, in tag: String) -> String? {
        let pattern = #"\b\#(name)\s*=\s*(?:"([^"]*)"|'([^']*)')"#
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let m = re.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)) else { return nil }
        for i in 1...2 {
            if let r = Range(m.range(at: i), in: tag) { return String(tag[r]) }
        }
        return nil
    }

    private static func pngData(from image: NSImage, side: Int) -> Data? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: side, height: side), from: .zero, operation: .copy, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }
}

enum IconProvider {
    static func icon(for target: String, side: CGFloat = 16) -> NSImage {
        let image: NSImage
        switch TargetResolver.resolve(target) {
        case .file(let url):
            image = (NSWorkspace.shared.icon(forFile: url.path).copy() as? NSImage) ?? NSImage()
        case .web(let url):
            image = url.host.flatMap(FaviconService.cached(host:)) ?? symbol("globe")
        case .other:
            image = symbol("link")
        case nil:
            image = symbol("questionmark.circle")
        }
        image.size = NSSize(width: side, height: side)
        return image
    }

    private static func symbol(_ name: String) -> NSImage {
        NSImage(systemSymbolName: name, accessibilityDescription: nil) ?? NSImage()
    }
}
