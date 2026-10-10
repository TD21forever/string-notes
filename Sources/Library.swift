import Cocoa
import SwiftUI

struct LibraryView: View {
    @ObservedObject var store: Store
    let edit: (Memo) -> Void
    @AppStorage("reduceMotion") private var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) var systemReduceMotion
    @State private var query = ""
    @State private var section = 0
    @State private var abandoning: UUID?
    init(store: Store, edit: @escaping (Memo) -> Void, initialSection: Int = 0) {
        self.store = store; self.edit = edit; _section = State(initialValue: initialSection)
    }
    var items: [Memo] {
        let list = section == 0 ? store.active : section == 1 ? store.notes.filter(\.done) : section == 2 ? store.drafts : store.book.trash.map(\.note)
        return query.isEmpty ? list : list.filter { $0.text.localizedStandardContains(query) }
    }
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(nsImage: Brand.menuIcon()).frame(width: 26)
                TextField("找回一个念头…", text: $query).textFieldStyle(.roundedBorder).accessibilityLabel("搜索便笺")
            }
            Picker("便笺分类", selection: $section) {
                Text("绳上 \(store.active.count)").tag(0)
                Text("归档 \(store.notes.filter(\.done).count)").tag(1)
                Text("草稿 \(store.drafts.count)").tag(2)
                Text("回收站 \(store.book.trash.count)").tag(3)
            }.pickerStyle(.segmented)
            if items.isEmpty {
                Spacer()
                ToolIcon(name: query.isEmpty ? "tray" : "magnifyingglass").scaleEffect(1.7).foregroundStyle(.secondary)
                Text(query.isEmpty ? "这里暂时空着" : "没有找到这个念头").foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(items) { note in
                            HStack(alignment: .top, spacing: 12) {
                                RoundedRectangle(cornerRadius: 2).fill(papers[max(0,min(3,note.color))]).frame(width: 5)
                                Button { if section != 3 { edit(note) } } label: {
                                    Text(note.text.isEmpty ? "空白草稿" : NoteDocument.preview(note)).font(.system(size: 13)).lineLimit(3).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                                }.buttonStyle(.plain).disabled(section == 3)
                                if section == 3 {
                                    Button("找回") { store.restore(note.id) }
                                } else if section == 1 {
                                    Button("挂回绳上") { if store.drafts.contains(where: {$0.id == note.id}) { edit(note) } else { var n = note; n.done = false; store.put(n) } }
                                } else if section == 2 {
                                    Button("放弃草稿") { abandoning = note.id }.help("删除草稿；已经挂上的原便笺保留")
                                } else {
                                    Button { if store.drafts.contains(where: {$0.id == note.id}) { edit(note) } else { var n = note; n.done = true; store.put(n) } } label: { ToolIcon(name: "archivebox") }.help("完成并收进归档").accessibilityLabel("归档便笺")
                                }
                            }.padding(12).frame(minHeight: 64).modifier(HoverRow())
                                .transition(reduceMotion || systemReduceMotion ? .identity : .opacity.combined(with: .offset(y: 6)))
                        }
                    }.animation(reduceMotion || systemReduceMotion ? nil : .easeInOut(duration: 0.2), value: items.map(\.id))
                }
            }
            if !store.error.isEmpty { Text(store.error).font(.caption).foregroundStyle(.red).textSelection(.enabled) }
            HStack { Text("绳上只留眼前的事，做完的收进盒子。"); Spacer() }.font(.system(size: 11)).foregroundStyle(.secondary)
        }.padding(22).frame(minWidth: 460, minHeight: 340)
            .alert("放弃这份草稿？", isPresented: Binding(get: { abandoning != nil }, set: { if !$0 { abandoning = nil } })) {
                Button("保留", role: .cancel) { abandoning = nil }
                Button("放弃草稿", role: .destructive) { if let id = abandoning { store.discardDraft(id) }; abandoning = nil }
            } message: { Text("草稿中的修改无法恢复，已经挂上的原便笺会保留。") }
    }
}
