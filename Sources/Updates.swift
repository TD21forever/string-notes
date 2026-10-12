import Cocoa
import Combine
import Sparkle

enum AppVersion {
    static var current: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.12.0" }
    static var architecture: String {
        #if arch(arm64)
        return "arm64"
        #else
        return "x86_64"
        #endif
    }
}

enum UpdatePreferences {
    static func migrate(_ defaults: UserDefaults) {
        // Preserve the old opt-out, while allowing Sparkle to own future scheduling.
        if defaults.object(forKey: "SUEnableAutomaticChecks") == nil {
            defaults.set(defaults.object(forKey: "automaticUpdateChecks") as? Bool ?? true, forKey: "SUEnableAutomaticChecks")
        }
    }
}

final class UpdateChecker: NSObject, ObservableObject, SPUUpdaterDelegate {
    static let shared = UpdateChecker()
    @Published private(set) var canCheck = false
    @Published private(set) var error = ""
    var willRelaunch: () -> Void = {}
    private var controller: SPUStandardUpdaterController!
    private var started = false

    override init() {
        super.init()
        UpdatePreferences.migrate(.standard)
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil)
        controller.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheck)
    }
    func start() {
        guard !started else { return }
        do {
            try controller.updater.start()
            started = true; error = ""
        } catch { self.error = L("更新器无法启动，请重试或手动下载新版。") }
    }
    func setAutomaticChecks(_ enabled: Bool) {
        controller.updater.automaticallyChecksForUpdates = enabled
    }
    func check() {
        start()
        guard canCheck else { return }
        error = ""
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }
    func updaterWillRelaunchApplication(_ updater: SPUUpdater) { willRelaunch() }
}
