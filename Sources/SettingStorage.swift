import Combine
import SwiftUI

// Publish edits immediately instead of waiting for UserDefaults to invalidate
// the settings window. Other writers (including Sparkle) still stay in sync.
final class SettingValue<Value: Equatable>: ObservableObject {
    @Published private(set) var value: Value
    private let key: String
    private let fallback: Value
    private let defaults: UserDefaults
    private var observation: AnyCancellable?

    init(key: String, fallback: Value, defaults: UserDefaults) {
        self.key = key
        self.fallback = fallback
        self.defaults = defaults
        value = defaults.object(forKey: key) as? Value ?? fallback
        observation = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: defaults)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
    }

    func set(_ newValue: Value) {
        guard value != newValue else { return }
        value = newValue
        defaults.set(newValue, forKey: key)
    }

    private func reload() {
        let saved = defaults.object(forKey: key) as? Value ?? fallback
        if value != saved { value = saved }
    }
}

@propertyWrapper
struct SettingStorage<Value: Equatable>: DynamicProperty {
    @StateObject private var state: SettingValue<Value>

    init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) {
        _state = StateObject(wrappedValue: SettingValue(key: key, fallback: wrappedValue, defaults: store))
    }

    var wrappedValue: Value {
        get { state.value }
        nonmutating set { state.set(newValue) }
    }

    var projectedValue: Binding<Value> {
        Binding(get: { state.value }, set: { state.set($0) })
    }
}
