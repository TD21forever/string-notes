import Cocoa
import Combine

struct RopeDisplay: Identifiable {
    let id: String
    let name: String
    let screen: NSScreen
}
enum DisplayChoice {
    // First NSScreen is the menu-bar display; NSScreen.main follows keyboard focus.
    static func resolve(_ selection: String, available: [String], mouse: String?) -> String? {
        if selection == "mouse", let mouse = mouse, available.contains(mouse) { return mouse }
        return available.contains(selection) ? selection : available.first
    }
}
final class DisplayPreferences: ObservableObject {
    static let shared = DisplayPreferences()
    @Published private(set) var displays: [RopeDisplay] = []
    private init() {
        refresh()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    @objc func refresh() {
        displays = NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
                  let uuid = CGDisplayCreateUUIDFromDisplayID(number.uint32Value)?.takeRetainedValue() else { return nil }
            let id = CFUUIDCreateString(nil, uuid)! as String
            return RopeDisplay(id: id, name: screen.localizedName, screen: screen)
        }
    }
    func screen(at point: NSPoint) -> NSScreen? {
        let selection = UserDefaults.standard.string(forKey: "ropeDisplay") ?? "mouse"
        let mouse = displays.first { $0.screen.frame.contains(point) }?.id
        let id = DisplayChoice.resolve(selection, available: displays.map(\.id), mouse: mouse)
        return displays.first { $0.id == id }?.screen ?? NSScreen.screens.first
    }
}
