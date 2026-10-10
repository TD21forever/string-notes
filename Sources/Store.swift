import Foundation
import Combine

struct Memo: Codable, Identifiable, Equatable {
    var id = UUID()
    var text: String
    var color: Int = 0
    var done = false
    var staysOnTop: Bool? = nil
    var richText: Data? = nil
}
struct RemovedMemo: Codable { var note: Memo; var index: Int }
struct Notebook: Codable {
    var version = 1
    var notes: [Memo] = []
    var drafts: [Memo] = []
    var trash: [RemovedMemo] = []
}
final class Store: ObservableObject {
    @Published private(set) var book = Notebook()
    @Published var error = ""
    @Published var message = "" {
        didSet {
            guard !message.isEmpty else { return }
            let expected = message
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.message == expected { self?.message = "" }
            }
        }
    }
    var notes: [Memo] { book.notes }
    var active: [Memo] { notes.filter { !$0.done } }
    var drafts: [Memo] { book.drafts }
    // Recovery drafts remain intact until opening the note successfully saves them.
    var libraryNotes: [Memo] {
        let recovered = Dictionary(book.drafts.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        let ids = Set(notes.map(\.id))
        return notes.map { recovered[$0.id] ?? $0 } + drafts.filter { !ids.contains($0.id) }
    }
    let file: URL
    private var blocked = false
    private var previousOrder: [Memo]?
    var canUndoOrder: Bool { previousOrder != nil }
    init(folder: URL? = nil, seedWelcome: Bool = true) {
        let folder = folder ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("StringNotes")
        file = folder.appendingPathComponent("notes.json")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: file.path) {
                let data = try Data(contentsOf: file)
                if let legacy = try? JSONDecoder().decode([Memo].self, from: data) {
                    book.notes = legacy
                    try data.write(to: folder.appendingPathComponent("notes-before-v3.json"), options: .atomic)
                } else {
                    let decoded = try JSONDecoder().decode(Notebook.self, from: data)
                    guard decoded.version == 1 else { throw CocoaError(.fileReadCorruptFile) }
                    book = decoded
                }
            } else if seedWelcome {
                var first = Notebook()
                first.notes = [Memo(text: L("欢迎使用绳上便笺\n\n把眼前的小事，挂在绳子上。\n\n鼠标停在菜单栏展开，点 ＋ 新建，拖动夹子排序。\n\n写下即自动保存，Esc 关闭。点图钉可让窗口保持最前。\n\n右键菜单栏打开便笺盒和设置，可查找、归档并自定义全局快捷键。"))]
                commit(first)
            }
        } catch { blocked = true; self.error = L("无法读取便笺，已停止写入以保护原文件。请从设置打开数据目录检查或恢复备份。") }
    }
    @discardableResult private func commit(_ next: Notebook) -> Bool {
        guard !blocked else { return false }
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(next).write(to: file, options: .atomic)
            book = next; error = ""; return true
        } catch { self.error = L("保存失败，内容尚未写入磁盘。请保留窗口，复制文字或检查数据目录后重试。"); return false }
    }
    @discardableResult func autoSave(_ note: Memo) -> Bool {
        if notes.first(where: { $0.id == note.id }) == note && !drafts.contains(where: { $0.id == note.id }) { return true }
        if note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !notes.contains(where: { $0.id == note.id }) { return discardDraft(note.id) }
        var next = book
        if let i = next.notes.firstIndex(where: { $0.id == note.id }) { next.notes[i] = note } else { next.notes.append(note) }
        next.drafts.removeAll { $0.id == note.id }
        return commit(next)
    }
    @discardableResult func importBackup(_ data: Data) throws -> Int {
        let incoming = try JSONDecoder().decode(Notebook.self, from: data)
        let primaryIDs = incoming.notes.map(\.id) + incoming.trash.map { $0.note.id }
        guard incoming.version == 1, Set(primaryIDs).count == primaryIDs.count,
              Set(incoming.drafts.map(\.id)).count == incoming.drafts.count else { throw CocoaError(.fileReadCorruptFile) }
        let known = Set(notes.map(\.id) + drafts.map(\.id) + book.trash.map { $0.note.id })
        var next = book
        next.notes += incoming.notes.filter { !known.contains($0.id) }
        next.drafts += incoming.drafts.filter { !known.contains($0.id) }
        next.trash += incoming.trash.filter { !known.contains($0.note.id) }
        let added = Set(primaryIDs + incoming.drafts.map(\.id)).subtracting(known).count
        guard added > 0 else { return 0 }
        guard commit(next) else { throw CocoaError(.fileWriteUnknown) }
        return added
    }
    @discardableResult func draft(_ note: Memo) -> Bool {
        if book.notes.first(where: {$0.id == note.id}) == note {
            if !book.drafts.contains(where: {$0.id == note.id}) { return true }
            return discardDraft(note.id)
        }
        if book.drafts.first(where: {$0.id == note.id}) == note { return true }
        if note.text.isEmpty && !book.drafts.contains(where: {$0.id == note.id}) && !notes.contains(where: {$0.id == note.id}) { return true }
        var next = book
        next.drafts.removeAll { $0.id == note.id }
        if !note.text.isEmpty || notes.contains(where: {$0.id == note.id}) { next.drafts.append(note) }
        return commit(next)
    }
    @discardableResult func discardDraft(_ id: UUID) -> Bool {
        var next = book; next.drafts.removeAll { $0.id == id }; return commit(next)
    }
    @discardableResult func put(_ note: Memo) -> Bool {
        var next = book
        if let i = next.notes.firstIndex(where: {$0.id == note.id}) { next.notes[i] = note } else { next.notes.append(note) }
        next.drafts.removeAll { $0.id == note.id }
        let ok = commit(next); if ok { message = note.done ? L("已收进归档") : L("已挂上绳子") }; return ok
    }
    @discardableResult func delete(_ id: UUID) -> Bool {
        var next = book
        guard let i = next.notes.firstIndex(where: {$0.id == id}) else { return false }
        next.trash.append(RemovedMemo(note: next.notes.remove(at: i), index: i))
        next.drafts.removeAll { $0.id == id }
        let ok = commit(next); if ok { message = L("已移到回收站，可以撤销") }; return ok
    }
    @discardableResult func restore(_ id: UUID? = nil) -> Bool {
        var next = book
        guard let i = id.flatMap({ id in next.trash.firstIndex(where: {$0.note.id == id}) }) ?? (id == nil ? next.trash.indices.last : nil) else { return false }
        let item = next.trash.remove(at: i)
        guard !next.notes.contains(where: {$0.id == item.note.id}) else { return false }
        next.notes.insert(item.note, at: min(item.index, next.notes.count))
        let ok = commit(next); if ok { message = L("便笺已找回") }; return ok
    }
    @discardableResult func place(_ id: UUID, before target: UUID?) -> Bool {
        guard target != id else { return true }
        var next = book
        guard let from = next.notes.firstIndex(where: { $0.id == id }),
              target == nil || next.notes.contains(where: { $0.id == target }) else { return false }
        let previous = next.notes
        let note = next.notes.remove(at: from)
        let index = target.flatMap { target in next.notes.firstIndex(where: { $0.id == target }) } ?? next.notes.endIndex
        next.notes.insert(note, at: index)
        if next.notes == book.notes { return true }
        guard commit(next) else { return false }
        previousOrder = previous
        return true
    }
    @discardableResult func move(_ id: UUID, to target: UUID) -> Bool {
        var next = book
        guard let from = next.notes.firstIndex(where: {$0.id == id}), let to = next.notes.firstIndex(where: {$0.id == target}), from != to else { return false }
        let before = next.notes
        next.notes.insert(next.notes.remove(at: from), at: to)
        let ok = commit(next); if ok { previousOrder = before; message = L("顺序已调整") }; return ok
    }
    @discardableResult func undoOrder() -> Bool {
        guard let order = previousOrder else { return false }
        var next = book
        let byID = Dictionary(uniqueKeysWithValues: next.notes.map { ($0.id, $0) })
        let ids = Set(order.map(\.id))
        next.notes = order.compactMap { byID[$0.id] } + next.notes.filter { !ids.contains($0.id) }
        let ok = commit(next); if ok { previousOrder = nil; message = L("已撤销排序") }; return ok
    }
}
