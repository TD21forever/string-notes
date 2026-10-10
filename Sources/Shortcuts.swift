import Cocoa
import Carbon
import SwiftUI

struct KeyBinding: Codable, Equatable {
    var key: UInt32
    var modifiers: UInt32
    var label: String
}
final class Shortcuts: ObservableObject {
    static let shared = Shortcuts()
    static let titles = ["new": L("新建便笺"), "library": L("所有便笺"), "archive": L("归档窗口"), "line": L("展开或收起绳子")]
    static let order = ["new", "library", "archive", "line"]
    @Published var bindings: [String: KeyBinding] = [:]
    @Published var errors: [String: String] = [:]
    var perform: ((String) -> Void)?
    private var refs: [String: EventHotKeyRef] = [:]
    private var handler: EventHandlerRef?
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "globalShortcuts"), let values = try? JSONDecoder().decode([String: KeyBinding].self, from: data) { bindings = values }
        else {
            let mods = UInt32(controlKey | optionKey | cmdKey)
            bindings = ["new": .init(key: 45, modifiers: mods, label: "⌃⌥⌘N"), "library": .init(key: 0, modifiers: mods, label: "⌃⌥⌘A"), "archive": .init(key: 37, modifiers: mods, label: "⌃⌥⌘L"), "line": .init(key: 1, modifiers: mods, label: "⌃⌥⌘S")]
        }
    }
    func start() {
        guard handler == nil else { return }
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, pointer -> OSStatus in
            guard let event = event, let pointer = pointer else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id) == noErr,
                id.signature == 0x534E4F54, id.id > 0, id.id <= UInt32(Shortcuts.order.count) else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<Shortcuts>.fromOpaque(pointer).takeUnretainedValue()
            owner.perform?(Shortcuts.order[Int(id.id) - 1]); return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard status == noErr else { errors["new"] = L("无法启动全局快捷键（%d）", status); return }
        for action in Self.order { if let binding = bindings[action] { register(action, binding) } }
    }
    @discardableResult private func register(_ action: String, _ binding: KeyBinding) -> Bool {
        guard let index = Self.order.firstIndex(of: action) else { return false }
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(binding.key, binding.modifiers, EventHotKeyID(signature: 0x534E4F54, id: UInt32(index + 1)), GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref = ref else { errors[action] = L("此组合可能已被系统或其他应用占用，请换一组（%d）。", status); return false }
        if let old = refs[action] { UnregisterEventHotKey(old) }
        refs[action] = ref; errors[action] = nil; return true
    }
    func set(_ action: String, _ binding: KeyBinding?) {
        if let binding = binding {
            guard !bindings.contains(where: { $0.key != action && $0.value.key == binding.key && $0.value.modifiers == binding.modifiers }) else { errors[action] = L("此组合已分配给另一个操作。"); return }
            if bindings[action] == binding && refs[action] != nil { return }
            guard register(action, binding) else { return }
            bindings[action] = binding
        } else {
            if let ref = refs.removeValue(forKey: action) { UnregisterEventHotKey(ref) }
            bindings[action] = nil; errors[action] = nil
        }
        if let data = try? JSONEncoder().encode(bindings) { defaults.set(data, forKey: "globalShortcuts") }
    }
    func suspend() { for ref in refs.values { UnregisterEventHotKey(ref) }; refs.removeAll() }
    func resume() { for action in Self.order { if let binding = bindings[action] { register(action, binding) } } }
    deinit { for ref in refs.values { UnregisterEventHotKey(ref) }; if let handler = handler { RemoveEventHandler(handler) } }
}
final class RecorderButton: NSButton {
    var capture: ((KeyBinding?) -> Void)?
    private var monitor: Any?
    private var priorTitle = ""
    override var acceptsFirstResponder: Bool { true }
    @objc func beginRecording() {
        guard monitor == nil else { return }
        priorTitle = title; title = L("按下组合键…"); window?.makeFirstResponder(self)
        Shortcuts.shared.suspend()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, event.window === self.window, self.window?.firstResponder === self else { return event }
            if event.keyCode == 53 { self.stop(); return nil }
            if event.keyCode == 51 || event.keyCode == 117 { self.stop(); self.capture?(nil); return nil }
            let flags = event.modifierFlags.intersection([.control, .option, .shift, .command])
            guard flags.contains(.control) || flags.contains(.command) || flags.contains(.option) else { self.title = L("请加 ⌘、⌥ 或 ⌃"); return nil }
            var mods: UInt32 = 0; var label = ""
            for (flag, value, symbol): (NSEvent.ModifierFlags, Int, String) in [(.control, controlKey, "⌃"), (.option, optionKey, "⌥"), (.shift, shiftKey, "⇧"), (.command, cmdKey, "⌘")] {
                if flags.contains(flag) { mods |= UInt32(value); label += symbol }
            }
            let special: [UInt16:String] = [49:L("空格"),36:"↩",48:"⇥",123:"←",124:"→",125:"↓",126:"↑"]
            label += special[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? L("键%d", Int(event.keyCode))
            let binding = KeyBinding(key: UInt32(event.keyCode), modifiers: mods, label: label)
            self.stop(); self.capture?(binding); return nil
        }
    }
    func stop() { guard let monitor = monitor else { return }; NSEvent.removeMonitor(monitor); self.monitor = nil; title = priorTitle; Shortcuts.shared.resume() }
    override func resignFirstResponder() -> Bool { stop(); return super.resignFirstResponder() }
    deinit { if let monitor = monitor { NSEvent.removeMonitor(monitor) } }
}
struct ShortcutRecorder: NSViewRepresentable {
    let title: String
    let capture: (KeyBinding?) -> Void
    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton(title: title, target: nil, action: nil); button.bezelStyle = .rounded; button.target = button; button.action = #selector(RecorderButton.beginRecording); button.capture = capture; return button
    }
    static func dismantleNSView(_ button: RecorderButton, coordinator: ()) { button.stop() }
    func updateNSView(_ button: RecorderButton, context: Context) { button.title = title; button.capture = capture }
}
struct ShortcutSettings: View {
    @ObservedObject var shortcuts = Shortcuts.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Shortcuts.order, id: \.self) { action in
                HStack {
                    Text(Shortcuts.titles[action]!).font(.system(size: 12)); Spacer()
                    ShortcutRecorder(title: shortcuts.bindings[action]?.label ?? L("未设置")) { shortcuts.set(action, $0) }.frame(width: 145, height: 26)
                }
                if let error = shortcuts.errors[action] { Text(error).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true) }
            }
        }
    }
}
