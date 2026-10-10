import Cocoa
import Combine

// Numeric versions are compared component-by-component, never as strings.
struct ReleaseVersion: Comparable, Equatable {
    let numbers: [Int]
    let prerelease: [String]
    init?(_ raw: String) {
        let value = raw.hasPrefix("v") ? String(raw.dropFirst()) : raw
        let core = value.split(separator: "+", maxSplits: 1, omittingEmptySubsequences: false)[0]
        let parts = core.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let components = parts[0].split(separator: ".", omittingEmptySubsequences: false)
        guard (2...3).contains(components.count), components.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }),
              components.allSatisfy({ Int($0) != nil }) else { return nil }
        numbers = components.map { Int($0)! } + Array(repeating: 0, count: 3 - components.count)
        if parts.count == 2 {
            let labels = parts[1].split(separator: ".", omittingEmptySubsequences: false).map(String.init)
            guard labels.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") } }) else { return nil }
            prerelease = labels
        } else { prerelease = [] }
    }
    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.numbers != rhs.numbers { return lhs.numbers.lexicographicallyPrecedes(rhs.numbers) }
        if lhs.prerelease.isEmpty || rhs.prerelease.isEmpty { return !lhs.prerelease.isEmpty && rhs.prerelease.isEmpty }
        for (a, b) in zip(lhs.prerelease, rhs.prerelease) where a != b {
            if let x = Int(a), let y = Int(b) { return x < y }
            if Int(a) != nil { return true }
            if Int(b) != nil { return false }
            return a < b
        }
        return lhs.prerelease.count < rhs.prerelease.count
    }
}
enum AppVersion {
    static var current: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.11.0" }
    static var architecture: String {
        #if arch(arm64)
        return "arm64"
        #else
        return "x86_64"
        #endif
    }
}
struct GitHubRelease: Decodable, Equatable {
    struct Asset: Decodable, Equatable {
        let name: String
        let browser_download_url: String
    }
    let tag_name: String
    let html_url: String
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]
    var version: ReleaseVersion? { ReleaseVersion(tag_name) }
    var pageURL: URL? {
        guard let url = URL(string: html_url), url.scheme == "https", url.host == "github.com",
              url.user == nil, url.password == nil,
              url.path.hasPrefix("/TD21forever/string-notes/releases/tag/") else { return nil }
        return url
    }
    func downloadURL(architecture: String) -> URL? {
        let version = tag_name.hasPrefix("v") ? String(tag_name.dropFirst()) : tag_name
        let expected = "StringNotes-\(version)-\(architecture).zip"
        guard let asset = assets.first(where: { $0.name == expected }),
              let url = URL(string: asset.browser_download_url), url.scheme == "https", url.host == "github.com",
              url.user == nil, url.password == nil,
              url.path == "/TD21forever/string-notes/releases/download/\(tag_name)/\(expected)" else { return nil }
        return url
    }
    static func newest(in data: Data, current: String) throws -> GitHubRelease? {
        guard let installed = ReleaseVersion(current) else { throw URLError(.cannotParseResponse) }
        let releases = try JSONDecoder().decode([Self].self, from: data)
        // This app ships as a preview: GitHub's /latest endpoint omits its releases.
        return releases.filter { !$0.draft && $0.pageURL != nil && $0.version.map { $0 > installed } == true }
            .max { $0.version! < $1.version! }
    }
}
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    enum State: Equatable { case idle, checking, current, available(GitHubRelease), failed }
    @Published private(set) var state: State = .idle
    private var task: Task<Void, Never>?
    private let defaults: UserDefaults
    private let fetch: () async throws -> Data
    private let installedVersion: String
    init(defaults: UserDefaults = .standard, installedVersion: String = AppVersion.current,
         fetch: @escaping () async throws -> Data = UpdateChecker.fetchReleases) {
        self.defaults = defaults; self.installedVersion = installedVersion; self.fetch = fetch
    }
    static func fetchReleases() async throws -> Data {
        let url = URL(string: "https://api.github.com/repos/TD21forever/string-notes/releases?per_page=100")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("StringNotes/\(AppVersion.current)", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200, data.count < 5_000_000 else { throw URLError(.badServerResponse) }
        return data
    }
    func checkAutomatically(now: Date = Date()) {
        guard defaults.object(forKey: "automaticUpdateChecks") as? Bool ?? true else { return }
        if let last = defaults.object(forKey: "lastUpdateCheck") as? Date, now.timeIntervalSince(last) < 86400 { return }
        check()
    }
    func check() {
        guard task == nil else { return }
        state = .checking
        // Record attempts too, so an offline launch never causes a retry loop.
        defaults.set(Date(), forKey: "lastUpdateCheck")
        task = Task { @MainActor [weak self] in
            guard let self = self else { return }
            defer { self.task = nil }
            do {
                let data = try await self.fetch()
                if let release = try GitHubRelease.newest(in: data, current: self.installedVersion) { self.state = .available(release) }
                else { self.state = .current }
            } catch { self.state = .failed }
        }
    }
}
