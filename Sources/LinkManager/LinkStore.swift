import AppKit
import Combine

final class LinkStore: ObservableObject {
    @Published var links: [Link] = []
    /// Bumped whenever a favicon finished downloading, so views can refresh.
    @Published var iconRevision = 0

    private var cancellable: AnyCancellable?
    private var inFlight = Set<String>()

    static let supportDir: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LinkManager", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    private var fileURL: URL { Self.supportDir.appendingPathComponent("links.json") }

    init() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Link].self, from: data) {
            links = saved
        }
        fetchMissingIcons()
        cancellable = $links
            .dropFirst()
            .debounce(for: .milliseconds(700), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.save()
                self?.fetchMissingIcons()
            }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(links) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func fetchMissingIcons() {
        for link in links {
            guard case .web(let url) = TargetResolver.resolve(link.target),
                  let host = url.host,
                  FaviconService.cached(host: host) == nil,
                  inFlight.insert(host).inserted else { continue }
            Task { [weak self] in
                await FaviconService.fetch(for: url)
                await MainActor.run {
                    self?.inFlight.remove(host)
                    self?.iconRevision += 1
                }
            }
        }
    }
}
