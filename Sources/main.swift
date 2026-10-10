import Cocoa
import SwiftUI
import UniformTypeIdentifiers

let papers: [Color] = [Color(red: 1, green: 0.92, blue: 0.65), Color(red: 0.83, green: 0.91, blue: 0.83), Color(red: 0.96, green: 0.82, blue: 0.79), Color(red: 0.83, green: 0.88, blue: 0.96)]

// Rope geometry and metallic clip adapted from Tendedero (MIT); see THIRD_PARTY_NOTICES.md.
enum HangingLayout {
    static let height: CGFloat = 222
    static let cardWidth: CGFloat = 164
    static let cardHeight: CGFloat = 142
    static let step: CGFloat = 190
    static func ropeY(_ x: CGFloat, _ width: CGFloat) -> CGFloat {
        let f = max(0, min(1, x / max(width, 1)))
        return 10 + 4 * min(30, width * 0.018) * f * (1 - f)
    }
    static func x(_ index: Int, count: Int, width: CGFloat, scroll: CGFloat) -> CGFloat {
        let total = CGFloat(count) * step + 58
        return max(100, (width - total) / 2 + cardWidth / 2) + CGFloat(index) * step - scroll
    }
    static func maxScroll(count: Int, width: CGFloat) -> CGFloat { max(0, CGFloat(count) * step + 190 - width) }
}
final class Presentation: ObservableObject {
    @Published var revealed = false
    @Published var scroll: CGFloat = 0
    @Published var detached: Set<UUID> = []
    @Published var draggedID: UUID?
    @Published var dropX: CGFloat?
    @Published var dropIndex: Int?
    @Published var insertingID: UUID?
    var hitRects: [CGRect] = []
}
struct HitRects: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) { value += nextValue() }
}
extension View {
    func recordsHitRect() -> some View {
        background(GeometryReader { g in Color.clear.preference(key: HitRects.self, value: [g.frame(in: .named("line"))]) })
    }
}
struct Rope: View {
    let width: CGFloat
    var path: Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 10))
            p.addQuadCurve(to: CGPoint(x: width, y: 10), control: CGPoint(x: width / 2, y: 10 + 2 * min(30, width * 0.018)))
        }
    }
    var body: some View {
        ZStack {
            path.stroke(.black.opacity(0.2), lineWidth: 1.4).offset(y: 1).blur(radius: 1)
            path.stroke(Color(white: 0.56), lineWidth: 1.1)
            path.stroke(.white.opacity(0.6), lineWidth: 0.4).offset(y: -0.4)
        }.mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.05), .init(color: .black, location: 0.95), .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing))
            .allowsHitTesting(false)
    }
}
struct Peg: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3.5)
            .fill(LinearGradient(colors: [Color(white: 0.62), Color(white: 0.95), Color(white: 0.8), Color(white: 0.6)], startPoint: .leading, endPoint: .trailing))
            .frame(width: 9, height: 26)
            .overlay(RoundedRectangle(cornerRadius: 3.5).stroke(.white.opacity(0.6), lineWidth: 0.5))
            .overlay(alignment: .top) { Capsule().fill(.black.opacity(0.35)).frame(width: 5, height: 1.4).padding(.top, 8.5) }
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1.5)
    }
}
struct MemoCard: View {
    let note: Memo
    let index: Int
    let revealed: Bool
    let edit: () -> Void
    let drag: (NSPoint?) -> Void
    let drop: (NSPoint) -> Void
    @AppStorage("reduceMotion") var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) var systemReduceMotion
    private var motionOff: Bool { reduceMotion || systemReduceMotion }
    @State var hover = false
    @State var swing: Double = 0
    var body: some View {
        VStack(spacing: -12) {
            Peg().padding(.horizontal, 13).contentShape(Rectangle()).zIndex(2)
                .help(L("向下拖取下，沿绳拖动排序"))
            Button(action: edit) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NoteDocument.preview(note)).font(.system(size: 14, weight: .regular)).lineSpacing(4)
                        .strikethrough(note.done).foregroundStyle(.black.opacity(note.done ? 0.4 : 0.82))
                        .lineLimit(6).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    if note.done { Image(systemName: "checkmark").font(.system(size: 10, weight: .semibold)).foregroundStyle(.black.opacity(0.35)) }
                }.padding(.horizontal, 15).padding(.top, 18).padding(.bottom, 12)
                    .frame(width: HangingLayout.cardWidth, height: HangingLayout.cardHeight)
                    .background(LinearGradient(colors: [papers[max(0,min(3,note.color))], papers[max(0,min(3,note.color))].opacity(0.96)], startPoint: .top, endPoint: .bottom))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.45), lineWidth: 0.6))
                    .shadow(color: .black.opacity(hover ? 0.23 : 0.16), radius: hover ? 10 : 6, x: 1, y: hover ? 7 : 4)
            }.buttonStyle(TactileButtonStyle()).help(L("点击编辑便笺")).accessibilityHidden(true)
        }.overlay { CardDragSurface(title: NoteDocument.preview(note), hovered: { hover = $0 }, clicked: edit, moved: drag, dropped: drop) }.recordsHitRect()
            .rotationEffect(.degrees(swing + (hover && !motionOff ? 0 : (index % 2 == 0 ? -1.5 : 1.2))), anchor: .init(x: 0.5, y: 9.5 / 156))
            .scaleEffect(hover && !motionOff ? 1.045 : 1, anchor: .top)
            .animation(motionOff ? nil : .spring(response: 0.25, dampingFraction: 0.82), value: hover)
            .offset(y: hover && !motionOff ? -4 : 0)
            .animation(motionOff ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: hover)
            .onChange(of: revealed) { visible in
                if visible && !motionOff {
                    swing = index % 2 == 0 ? 3 : -3
                    withAnimation(.interpolatingSpring(stiffness: 70, damping: 6).delay(Double(index % 6) * 0.035)) { swing = 0 }
                }
            }
    }
}
struct Board: View {
    @ObservedObject var store: Store
    @ObservedObject var presentation: Presentation
    let edit: (Memo?) -> Void
    let drag: (UUID, NSPoint?) -> Void
    let drop: (Memo, NSPoint) -> Void
    private var hanging: [Memo] { store.active.filter { !presentation.detached.contains($0.id) && $0.id != presentation.draggedID && $0.id != presentation.insertingID } }
    @AppStorage("reduceMotion") var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) var systemReduceMotion
    private var motionOff: Bool { reduceMotion || systemReduceMotion }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Rope(width: geo.size.width)
                if let x = presentation.dropX {
                    VStack(spacing: -12) {
                        Peg().opacity(0.55)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.white.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 5])))
                            .frame(width: HangingLayout.cardWidth, height: HangingLayout.cardHeight)
                    }.position(x: x, y: HangingLayout.ropeY(x, geo.size.width) - 9.5 + 78)
                        .allowsHitTesting(false)
                }
                ForEach(Array(hanging.enumerated()), id: \.element.id) { i, note in
                    let slot = i + ((presentation.dropIndex.map { i >= $0 } ?? false) ? 1 : 0)
                    let x = HangingLayout.x(slot, count: hanging.count + (presentation.dropIndex == nil ? 0 : 1), width: geo.size.width, scroll: presentation.scroll)
                    MemoCard(note: note, index: i, revealed: presentation.revealed, edit: { edit(note) }, drag: { drag(note.id, $0) }, drop: { drop(note, $0) })
                        .opacity(presentation.draggedID == note.id ? 0.25 : 1)
                        .transition(motionOff ? .identity : .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: -14)).combined(with: .scale(scale: 0.96, anchor: .top)),
                            removal: .opacity.combined(with: .offset(y: 10)).combined(with: .scale(scale: 0.94, anchor: .top))))
                        .position(x: x, y: HangingLayout.ropeY(x, geo.size.width) - 9.5 + 78)
                        .opacity(min(1, max(0, min(x - 25, geo.size.width - x - 25) / 65)))
                }
                let visibleSlots = hanging.count + (presentation.dropIndex == nil ? 0 : 1)
                let plusX = HangingLayout.x(visibleSlots, count: visibleSlots, width: geo.size.width, scroll: presentation.scroll) - 45
                Button { edit(nil) } label: {
                    Image(systemName: "plus").font(.system(size: 13, weight: .medium)).foregroundStyle(.primary)
                        .frame(width: 28, height: 28).background(.regularMaterial, in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 0.7))
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                }.buttonStyle(TactileButtonStyle()).help(L("写一张便笺")).accessibilityLabel(L("写一张便笺"))
                    .recordsHitRect().position(x: plusX, y: HangingLayout.ropeY(plusX, geo.size.width) + 22)
                if hanging.isEmpty && presentation.dropIndex == nil {
                    Text(L("写一张，把念头挂起来")).font(.system(size: 12)).padding(.horizontal, 12).padding(.vertical, 7)
                        .background(.regularMaterial, in: Capsule()).position(x: geo.size.width / 2, y: 102)
                }
                if !store.error.isEmpty {
                    Text(store.error).font(.caption).foregroundStyle(.red).padding(8).background(.regularMaterial, in: Capsule()).position(x: geo.size.width / 2, y: 200)
                }
            }.coordinateSpace(name: "line")
                .onChange(of: hanging.map(\.id)) { _ in
                    guard presentation.draggedID == nil, presentation.insertingID == nil else { return }
                    presentation.scroll = min(presentation.scroll, HangingLayout.maxScroll(count: hanging.count, width: geo.size.width))
                }
                .onPreferenceChange(HitRects.self) { presentation.hitRects = $0 }
                .offset(y: presentation.revealed ? 0 : -HangingLayout.height - 15)
                .animation(motionOff ? nil : presentation.revealed ? .spring(response: 0.42, dampingFraction: 0.82) : .easeIn(duration: 0.22), value: presentation.revealed)
                .animation(motionOff ? nil : .spring(response: 0.32, dampingFraction: 0.86), value: hanging.map(\.id))
                .animation(motionOff ? nil : .spring(response: 0.28, dampingFraction: 0.86), value: presentation.dropIndex)
        }
    }
}
final class LinePanel: NSPanel {
    var onScroll: ((NSEvent) -> Void)?
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func sendEvent(_ event: NSEvent) {
        if event.type == .scrollWheel { onScroll?(event) } else { super.sendEvent(event) }
    }
}
final class NoteTextView: ResizableImageTextView {
    var displayFont: NSFont?
    var imageMode = ""
    var markdownEnabled = true
    var styling = false
    func restyle() {
        guard !styling, !hasMarkedText(), let storage = textStorage else { return }
        styling = true
        MarkdownStyle.apply(storage, selection: selectedRange(), font: NotePreferences.font, enabled: markdownEnabled)
        typingAttributes = [.font: NotePreferences.font, .foregroundColor: NSColor.black.withAlphaComponent(0.82)]
        styling = false
    }
    override func insertNewline(_ sender: Any?) {
        if markdownEnabled, !hasMarkedText(), selectedRange().length == 0 {
            let text = string as NSString; let caret = selectedRange().location
            if let closing = MarkdownStyle.codeBlockExit(string, caret: caret) {
                insertText(closing, replacementRange: selectedRange())
                return
            }
            if MarkdownStyle.codeBlock(at: caret, in: string) != nil {
                super.insertNewline(sender)
                return
            }
            let range = text.lineRange(for: NSRange(location: caret, length: 0))
            let before = text.substring(with: NSRange(location: range.location, length: caret - range.location))
            if let list = MarkdownStyle.nextListPrefix(before) {
                if list.empty { insertText("", replacementRange: NSRange(location: range.location, length: caret - range.location)) }
                else { insertText("\n" + list.prefix, replacementRange: selectedRange()) }
                return
            }
        }
        super.insertNewline(sender)
    }
    var submit: (() -> Void)?
    var dismiss: (() -> Void)?
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 && event.modifierFlags.contains(.command) && !hasMarkedText() { submit?(); return }
        if event.keyCode == 53 && !hasMarkedText() {
            if enclosingScrollView?.isFindBarVisible == true { enclosingScrollView?.isFindBarVisible = false } else { dismiss?() }
            return
        }
        super.keyDown(with: event)
    }
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(paste(_:)), NSImage.canInit(with: .general) { return true }
        return super.validateUserInterfaceItem(item)
    }
    override func copy(_ sender: Any?) {
        let range = selectedRange()
        guard range.length > 0 else { return }
        let value = MarkdownStyle.canonical(attributedString().attributedSubstring(from: range), font: NotePreferences.font)
        let board = NSPasteboard.general; board.clearContents(); board.setString(value.string, forType: .string)
        if let data = NoteDocument.encode(value) { board.setData(data, forType: .rtfd) }
    }
    override func paste(_ sender: Any?) {
        if let image = NSImage(pasteboard: .general) { insertPicture(image); return }
        // Preserve attachments copied from a note; ordinary text keeps the paper's typography.
        if NSPasteboard.general.availableType(from: [.rtfd]) != nil { super.paste(sender) }
        else { pasteAsPlainText(sender) }
    }
    func insertPicture(_ image: NSImage) {
        guard let value = NoteDocument.image(image, width: NotePreferences.imageWidth(available: (textContainer?.containerSize.width ?? 320) - 12)) else { NSSound.beep(); return }
        let range = selectedRange()
        let startsMidLine = range.location > 0 && (string as NSString).substring(with: NSRange(location: range.location - 1, length: 1)) != "\n"
        let insertion = NSMutableAttributedString(string: startsMidLine ? "\n" : "", attributes: [.font: NotePreferences.font])
        insertion.append(value)
        insertion.append(NSAttributedString(string: "\n", attributes: [.font: NotePreferences.font]))
        insertText(insertion, replacementRange: selectedRange())
    }
    @objc func insertImage(_ sender: Any?) {
        let picker = NSOpenPanel(); picker.allowedContentTypes = [.image]; picker.allowsMultipleSelection = false
        guard let window = window else { return }
        picker.beginSheetModal(for: window) { [weak self] response in
            if response == .OK, let url = picker.url, let image = NSImage(contentsOf: url) { self?.insertPicture(image) }
        }
    }
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = super.menu(for: event) ?? NSMenu()
        let item = NSMenuItem(title: L("插入图片…"), action: #selector(insertImage(_:)), keyEquivalent: "")
        item.target = self; menu.addItem(.separator()); menu.addItem(item); return menu
    }
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if let storage = textStorage { NoteDocument.fitImages(storage, width: newSize.width - 48) }
    }
}
struct PaperTextEditor: NSViewRepresentable {
    @ObservedObject var session: EditSession
    @AppStorage("noteFont") var noteFont = "system"
    @AppStorage("noteFontSize") var noteFontSize = 17.0
    @AppStorage("imageSizing") var imageSizing = "fixed"
    @AppStorage("markdownEnabled") var markdownEnabled = true
    let submit: () -> Void
    let dismiss: () -> Void
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PaperTextEditor
        init(_ parent: PaperTextEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NoteTextView, !view.hasMarkedText(), !view.styling else { return }
            guard let data = NoteDocument.encode(MarkdownStyle.canonical(view.attributedString(), font: NotePreferences.font)) else { parent.session.status = L("保存失败"); parent.session.encodingFailed = true; return }
            var note = parent.session.note; note.text = view.string; note.richText = data
            parent.session.encodingFailed = false; parent.session.note = note
            view.restyle()
        }
        func textViewDidChangeSelection(_ notification: Notification) {
            (notification.object as? NoteTextView)?.restyle()
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView(); scroll.drawsBackground = false
        scroll.hasVerticalScroller = true; scroll.autohidesScrollers = true; scroll.scrollerStyle = .overlay
        let view = NoteTextView(); view.submit = submit; view.dismiss = dismiss
        view.isRichText = true; view.importsGraphics = true; view.allowsUndo = true; view.usesFindBar = true
        view.drawsBackground = false; view.textColor = NSColor.black.withAlphaComponent(0.82)
        view.insertionPointColor = .black; view.font = .systemFont(ofSize: 17)
        view.textContainerInset = NSSize(width: 20, height: 16)
        view.isVerticallyResizable = true; view.isHorizontallyResizable = false; view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = true
        view.textContainer?.containerSize = NSSize(width: 350, height: CGFloat.greatestFiniteMagnitude)
        view.textStorage?.setAttributedString(NoteDocument.decode(session.note))
        if let storage = view.textStorage { NoteDocument.fitImages(storage, width: 350) }
        view.delegate = context.coordinator; scroll.documentView = view
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        if let view = scroll.documentView as? NoteTextView {
            view.submit = submit; view.dismiss = dismiss
            let font = NotePreferences.font
            if view.displayFont != font || view.markdownEnabled != markdownEnabled {
                view.displayFont = font; view.markdownEnabled = markdownEnabled; view.restyle()
            }
            if view.imageMode != imageSizing {
                view.imageMode = imageSizing
                if let storage = view.textStorage { NoteDocument.fitImages(storage, width: view.frame.width - 48) }
                view.needsLayout = true; view.needsDisplay = true
            }
        }
    }
}
final class EditSession: ObservableObject {
    @Published var note: Memo
    @Published var status = L("已保存")
    var encodingFailed = false
    private var pending: DispatchWorkItem?
    init(_ note: Memo) { self.note = note; if note.text.isEmpty { status = L("输入后自动保存") } }
    func changed(_ store: Store) {
        cancelPending(); status = L("正在保存…")
        let work = DispatchWorkItem { [weak self, weak store] in
            guard let self = self, let store = store else { return }; _ = self.flush(store)
        }
        pending = work; DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }
    func cancelPending() { pending?.cancel(); pending = nil }
    @discardableResult func flush(_ store: Store) -> Bool {
        cancelPending(); guard !encodingFailed else { status = L("保存失败，请保留窗口并复制内容"); return false }; let ok = store.autoSave(note); status = ok ? L("已保存") : L("保存失败"); return ok
    }
    deinit { pending?.cancel() }
}
// A floating note should react on the first click, even when another app is active.
final class NoteHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
struct NoteToolbarIcon: View {
    let name: String
    @State private var hovered = false
    var body: some View {
        Image(systemName: name).font(.system(size: 13, weight: .regular))
            .frame(width: 36, height: 36)
            .background(hovered ? Color.black.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
            .onHover { hovered = $0 }
    }
}
struct Editor: View {
    @ObservedObject var session: EditSession
    @ObservedObject var store: Store
    let isNew: Bool
    let save: (Memo) -> Void
    let remove: () -> Void
    let close: () -> Void
    let pin: (Bool) -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                HStack {
                    Text(session.status).font(.system(size: 10)).foregroundStyle(.black.opacity(0.45))
                    Spacer()
                }.frame(maxWidth: .infinity, minHeight: 44)
                    .overlay { NoteWindowDragSurface() }.help(L("拖动窗口；拖回绳子可挂起"))
                Button { let value = !(session.note.staysOnTop ?? false); session.note.staysOnTop = value; pin(value) } label: {
                    NoteToolbarIcon(name: session.note.staysOnTop == true ? "pin.fill" : "pin")
                }.help(L("保持窗口最前")).accessibilityLabel(session.note.staysOnTop == true ? L("取消窗口置顶") : L("保持窗口最前"))
                Menu {
                    ForEach(0..<4) { i in
                        Button([L("奶黄色"), L("鼠尾草绿"), L("桃粉色"), L("雾蓝色")][i]) { session.note.color = i }
                    }
                    Divider()
                    Button(session.note.done ? L("挂回绳上") : L("归档便笺")) { session.note.done.toggle(); save(session.note) }
                    if store.notes.contains(where: { $0.id == session.note.id }) { Button(L("删除便笺"), action: remove) }
                } label: { NoteToolbarIcon(name: "ellipsis") }.menuStyle(.borderlessButton).menuIndicator(.hidden).frame(width: 36, height: 36).accessibilityLabel(L("便笺选项"))
                Button(action: close) { NoteToolbarIcon(name: "xmark") }.help(L("保存并关闭 · Esc")).accessibilityLabel(L("保存并关闭"))
            }.buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(.black.opacity(0.6))
                .padding(.leading, 18).padding(.trailing, 6).frame(height: 44).background(.black.opacity(0.035))
            PaperTextEditor(session: session, submit: { save(session.note) }, dismiss: close)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if !store.error.isEmpty || session.encodingFailed {
                Text(store.error.isEmpty ? L("内容转换失败，请保留窗口并复制内容。") : store.error)
                    .font(.system(size: 11)).foregroundStyle(.red).padding(12).textSelection(.enabled)
            }
        }.frame(minWidth: 280, minHeight: 220).ignoresSafeArea().background(papers[max(0,min(3,session.note.color))]).preferredColorScheme(.light)
            .onChange(of: session.note) { _ in session.changed(store) }
            .onAppear { if store.drafts.contains(where: { $0.id == session.note.id }) { session.changed(store) } }
    }
}
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let store = Store()
    var status: NSStatusItem!
    var panel: LinePanel!
    let presentation = Presentation()
    var pinned = false
    var menuSince: Date?
    var revealCooldown = Date.distantPast
    var editors: [UUID: (window: NSWindow, session: EditSession)] = [:]
    var library: NSWindow?
    var preferences: NSWindow?
    var timer: Timer?
    var outsideSince: Date?
    var enteredPanel = false
    var cardDragging = false
    var cardGhost: NSPanel?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(handleWindowDrag(_:)), name: .noteWindowDrag, object: nil)
        NSApp.setActivationPolicy(.accessory)
        let mainMenu = NSMenu()
        let appItem = NSMenuItem(); let appMenu = NSMenu()
        appMenu.addItem(withTitle: L("退出绳上便笺"), action: #selector(quit), keyEquivalent: "q").target = self
        appMenu.addItem(withTitle: L("写一张便笺"), action: #selector(newNote), keyEquivalent: "n").target = self
        appMenu.addItem(withTitle: L("便笺盒"), action: #selector(findNote), keyEquivalent: "f").target = self
        appMenu.addItem(withTitle: L("设置…"), action: #selector(openSettings), keyEquivalent: ",").target = self
        appMenu.addItem(withTitle: L("检查更新…"), action: #selector(checkForUpdates), keyEquivalent: "").target = self
        appItem.submenu = appMenu; mainMenu.addItem(appItem)
        let editItem = NSMenuItem(); editItem.title = L("编辑"); let editMenu = NSMenu(title: L("编辑"))
        for (title, selector, key) in [(L("撤销"), "undo:", "z"), (L("重做"), "redo:", "Z"), (L("剪切"), "cut:", "x"), (L("复制"), "copy:", "c"), (L("粘贴"), "paste:", "v"), (L("全选"), "selectAll:", "a")] {
            editMenu.addItem(withTitle: title, action: Selector(selector), keyEquivalent: key)
        }
        editItem.submenu = editMenu; mainMenu.addItem(editItem); NSApp.mainMenu = mainMenu
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.image = Brand.menuIcon()
        status.button?.toolTip = L("绳上便笺 · 点击展开，右键打开工具箱")
        status.button?.target = self; status.button?.action = #selector(toggle)
        status.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        panel = LinePanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.level = .floating; panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]; panel.hidesOnDeactivate = false
        panel.isMovable = false; panel.becomesKeyOnlyIfNeeded = true; panel.ignoresMouseEvents = true
        let host = NSHostingView(rootView: Board(store: store, presentation: presentation, edit: { [weak self] in self?.openEditor($0) }, drag: { [weak self] in self?.trackCard($0, point: $1) }, drop: { [weak self] in self?.dropCard($0, point: $1) }))
        host.wantsLayer = true; host.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = host
        panel.onScroll = { [weak self] event in
            guard let self = self else { return }
            let delta = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) ? event.scrollingDeltaX : event.scrollingDeltaY
            self.presentation.scroll = min(HangingLayout.maxScroll(count: self.store.active.count, width: self.panel.frame.width), max(0, self.presentation.scroll - delta))
        }
        Shortcuts.shared.perform = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case "new": self.newNote()
            case "library": self.openLibrary()
            case "archive": self.openArchive()
            default: if self.presentation.revealed { self.tuck() } else { self.show() }
            }
        }
        Shortcuts.shared.start()
        UpdateChecker.shared.checkAutomatically()
        scheduleTracking()
        show()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { show(); return true }
    @objc func toggle() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: L("新建便笺"), action: #selector(newNote), keyEquivalent: "n").target = self
            menu.addItem(withTitle: L("所有便笺"), action: #selector(openLibrary), keyEquivalent: "").target = self
            if store.canUndoOrder { menu.addItem(withTitle: L("撤销上次排序"), action: #selector(undoSort), keyEquivalent: "").target = self }
            menu.addItem(.separator())
            menu.addItem(withTitle: L("设置…"), action: #selector(openSettings), keyEquivalent: ",").target = self
            menu.addItem(withTitle: L("检查更新…"), action: #selector(checkForUpdates), keyEquivalent: "").target = self
            menu.addItem(.separator())
            menu.addItem(withTitle: L("退出绳上便笺"), action: #selector(quit), keyEquivalent: "q").target = self
            status.menu = menu; status.button?.performClick(nil); status.menu = nil
        } else if presentation.revealed { tuck() } else { show() }
    }
    @objc func newNote() { show(); openEditor(nil) }
    @objc func undoSort() { store.undoOrder() }
    func scheduleTracking() {
        timer?.invalidate()
        timer = Timer(timeInterval: presentation.revealed ? 0.04 : 0.16, repeats: true) { [weak self] _ in self?.trackPointer() }
        RunLoop.main.add(timer!, forMode: .common)
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        var failed: NSWindow?
        for entry in editors.values {
            if !entry.session.flush(store) { failed = entry.window }
        }
        if let failed = failed { failed.makeKeyAndOrderFront(nil); return .terminateCancel }
        return .terminateNow
    }
    @objc func findNote() {
        if let view = NSApp.keyWindow?.firstResponder as? NoteTextView {
            let item = NSMenuItem(); item.tag = NSTextFinder.Action.showFindInterface.rawValue
            view.performFindPanelAction(item)
        } else { openLibrary() }
    }
    @objc func openArchive() { presentLibrary(section: 1) }
    @objc func openLibrary() { presentLibrary(section: 0) }
    func presentLibrary(section: Int) {
        if let library = library {
            library.contentView = NSHostingView(rootView: LibraryView(store: store, edit: { [weak self] in self?.openEditor($0) }, initialSection: section))
            library.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return
        }
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 530, height: 480), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        win.title = L("便笺盒"); win.isReleasedWhenClosed = false
        win.contentView = NSHostingView(rootView: LibraryView(store: store, edit: { [weak self] in self?.openEditor($0) }, initialSection: section))
        win.minSize = NSSize(width: 490, height: 380); library = win; win.center(); win.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    @objc func checkForUpdates() {
        openSettings()
        preferences?.contentView = NSHostingView(rootView: SettingsView(store: store, showingUpdates: true))
        UpdateChecker.shared.check()
    }
    @objc func openSettings() {
        if let preferences = preferences { preferences.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 570), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        win.title = L("设置"); win.isReleasedWhenClosed = false; win.minSize = NSSize(width: 680, height: 500)
        win.contentView = NSHostingView(rootView: SettingsView(store: store))
        preferences = win; win.center(); win.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    @objc func quit() { NSApp.terminate(nil) }
    func show(pinned: Bool = true) {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: {$0.frame.contains(mouse)}) ?? NSScreen.main else { return }
        let rect = NSRect(x: screen.visibleFrame.minX, y: screen.visibleFrame.maxY - HangingLayout.height, width: screen.visibleFrame.width, height: HangingLayout.height)
        panel.setFrame(rect, display: true)
        presentation.scroll = min(presentation.scroll, HangingLayout.maxScroll(count: store.active.count, width: rect.width))
        panel.orderFrontRegardless(); outsideSince = nil; enteredPanel = false; self.pinned = pinned
        presentation.revealed = true; scheduleTracking()
    }
    func tuck() {
        guard editors.isEmpty, NSEvent.pressedMouseButtons == 0 else { return }
        presentation.revealed = false; panel.ignoresMouseEvents = true; scheduleTracking()
        pinned = false; menuSince = nil; revealCooldown = Date().addingTimeInterval(0.7)
    }
    func trackPointer() {
        let mouse = NSEvent.mouseLocation
        if cardDragging { return }
        let point = panel.convertPoint(fromScreen: mouse)
        let flipped = CGPoint(x: point.x, y: panel.frame.height - point.y)
        let overCard = presentation.hitRects.contains { $0.insetBy(dx: -6, dy: -6).contains(flipped) }
        let pressed = NSEvent.pressedMouseButtons != 0
        if presentation.revealed {
            // Keep the drag session alive even between cards.
            if !pressed { panel.ignoresMouseEvents = !overCard }
        } else { panel.ignoresMouseEvents = true }
        guard editors.isEmpty else { return }
        if pressed && !panel.ignoresMouseEvents { return }
        guard let screen = NSScreen.screens.first(where: {$0.frame.contains(mouse)}) else { return }
        let inMenuBar = mouse.y >= screen.visibleFrame.maxY && mouse.y <= screen.frame.maxY
        if !presentation.revealed {
            if inMenuBar && !pressed && Date() > revealCooldown && (UserDefaults.standard.object(forKey: "hoverReveal") as? Bool ?? true) {
                if let since = menuSince { if Date().timeIntervalSince(since) > 0.3 { show(pinned: false) } }
                else { menuSince = Date() }
            } else { menuSince = nil }
            return
        }
        if pressed && !overCard && panel.ignoresMouseEvents { pinned = false; enteredPanel = true }
        let inside = mouse.x >= panel.frame.minX && mouse.x <= panel.frame.maxX && mouse.y >= panel.frame.minY && mouse.y <= screen.frame.maxY
        if inside { outsideSince = nil; if !inMenuBar { enteredPanel = true } }
        else if !pinned || enteredPanel {
            if let since = outsideSince { if Date().timeIntervalSince(since) > 0.55 { tuck() } }
            else { outsideSince = Date() }
        }
    }
    // The rope is a temporary shelf: closing a detached window returns its note to it.
    func ropeTarget(_ point: NSPoint, excluding id: UUID) -> (before: UUID?, x: CGFloat, index: Int)? {
        guard presentation.revealed, point.x >= panel.frame.minX, point.x <= panel.frame.maxX,
              point.y <= panel.frame.maxY + 8, point.y >= panel.frame.maxY - 105 else { return nil }
        let notes = store.active.filter { !presentation.detached.contains($0.id) && $0.id != id }
        let localX = point.x - panel.frame.minX
        let first = HangingLayout.x(0, count: notes.count + 1, width: panel.frame.width, scroll: presentation.scroll)
        let index = max(0, min(notes.count, Int(((localX - first) / HangingLayout.step).rounded())))
        let x = HangingLayout.x(index, count: notes.count + 1, width: panel.frame.width, scroll: presentation.scroll)
        return (index < notes.count ? notes[index].id : nil, x, index)
    }
    func clearDropIndicator() {
        presentation.dropX = nil; presentation.dropIndex = nil; presentation.insertingID = nil
    }
    func updateDropIndicator(_ point: NSPoint, excluding id: UUID) {
        guard let target = ropeTarget(point, excluding: id) else { clearDropIndicator(); return }
        presentation.insertingID = id
        presentation.dropIndex = target.index
        presentation.dropX = target.x
    }
    func trackCard(_ id: UUID, point: NSPoint?) {
        cardDragging = point != nil
        presentation.draggedID = point == nil ? nil : id
        guard let point = point else {
            clearDropIndicator()
            cardGhost?.orderOut(nil); cardGhost = nil
            return
        }
        if cardGhost == nil, let note = store.notes.first(where: { $0.id == id }) {
            let ghost = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 164, height: 142), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            ghost.isOpaque = false; ghost.backgroundColor = .clear; ghost.hasShadow = true
            ghost.level = .popUpMenu; ghost.ignoresMouseEvents = true
            ghost.contentView = NSHostingView(rootView: Text(NoteDocument.preview(note)).font(.system(size: 14))
                .foregroundStyle(.black.opacity(0.82)).lineLimit(6).padding(15)
                .frame(width: 164, height: 142, alignment: .topLeading)
                .background(papers[max(0, min(3, note.color))], in: RoundedRectangle(cornerRadius: 5)))
            cardGhost = ghost
        }
        cardGhost?.setFrameOrigin(NSPoint(x: point.x - 82, y: point.y - 120))
        cardGhost?.orderFrontRegardless()
        updateDropIndicator(point, excluding: id)
    }
    func dropCard(_ note: Memo, point: NSPoint) {
        if let target = ropeTarget(point, excluding: note.id) {
            store.place(note.id, before: target.before)
        } else if point.y < panel.frame.maxY - 105 {
            openEditor(note)
            guard let entry = editors[note.id] else { return }
            presentation.detached.insert(note.id)
            let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? panel.screen
            let visible = screen?.visibleFrame ?? panel.frame
            // Keep the toolbar clear of the transparent rope panel's window bounds.
            let topLimit = screen == panel.screen ? panel.frame.minY - 8 : visible.maxY
            entry.window.setFrameOrigin(NSPoint(
                x: max(visible.minX, min(point.x - entry.window.frame.width / 2, visible.maxX - entry.window.frame.width)),
                y: max(visible.minY, min(point.y - entry.window.frame.height + 22, topLimit - entry.window.frame.height))))
        }
    }
    @objc func handleWindowDrag(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let id = editors.first(where: { $0.value.window === window })?.key,
              let point = notification.userInfo?["point"] as? NSPoint else { return }
        if notification.userInfo?["ended"] as? Bool == true {
            defer { clearDropIndicator() }
            guard let target = ropeTarget(point, excluding: id), let entry = editors[id] else { return }
            entry.session.note.done = false
            if entry.session.flush(store), !store.notes.contains(where: { $0.id == id }) || store.place(id, before: target.before) {
                // Close after mouse tracking has returned to AppKit's event loop.
                DispatchQueue.main.async { [weak self] in self?.finishEditor(id) }
            }
        } else {
            if let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }), screen != panel.screen {
                panel.setFrame(NSRect(x: screen.visibleFrame.minX, y: screen.visibleFrame.maxY - HangingLayout.height, width: screen.visibleFrame.width, height: HangingLayout.height), display: true)
            }
            presentation.revealed = true
            panel.orderFrontRegardless()
            updateDropIndicator(point, excluding: id)
        }
    }
    func openEditor(_ memo: Memo?) {
        if let id = memo?.id, let entry = editors[id] {
            entry.window.deminiaturize(nil); entry.window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true); return
        }
        let note: Memo
        if let memo = memo { note = store.drafts.first(where: {$0.id == memo.id}) ?? memo }
        else { note = store.drafts.first(where: { draft in editors[draft.id] == nil && !store.notes.contains(where: {$0.id == draft.id}) }) ?? Memo(text: "", color: max(0, min(3, UserDefaults.standard.integer(forKey: "defaultColor"))), staysOnTop: UserDefaults.standard.bool(forKey: "defaultPinned")) }
        let session = EditSession(note)
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 360), styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        win.titleVisibility = .hidden; win.titlebarAppearsTransparent = true; win.isMovableByWindowBackground = false
        win.standardWindowButton(.closeButton)?.isHidden = true; win.standardWindowButton(.miniaturizeButton)?.isHidden = true; win.standardWindowButton(.zoomButton)?.isHidden = true
        win.minSize = NSSize(width: 280, height: 220)
        win.setFrameAutosaveName("note-" + note.id.uuidString)
        win.title = note.text.split(separator: "\n").first.map { String($0.prefix(36)) } ?? L("新便笺"); win.isReleasedWhenClosed = false; win.delegate = self
        win.contentView = NoteHostingView(rootView: Editor(session: session, store: store, isNew: !store.notes.contains(where: {$0.id == note.id}), save: { [weak self] note in
            guard let self = self, let entry = self.editors[note.id], entry.session.flush(self.store) else { return }; self.finishEditor(note.id)
        }, remove: { [weak self] in
            guard let self = self, let entry = self.editors[note.id], entry.session.flush(self.store), self.store.delete(note.id) else { return }; self.finishEditor(note.id)
        }, close: { [weak win] in win?.performClose(nil) }, pin: { [weak win] value in win?.level = value ? .floating : .normal }))
        win.level = note.staysOnTop == true ? .floating : .normal
        editors[note.id] = (win, session)
        if let screen = panel.screen {
            let index = store.active.firstIndex(where: {$0.id == note.id}) ?? (store.active.count + editors.values.filter { $0.session.note.text.isEmpty }.count - 1)
            let x = panel.frame.minX + HangingLayout.x(index, count: store.active.count, width: panel.frame.width, scroll: presentation.scroll)
            win.setFrameOrigin(NSPoint(x: min(screen.visibleFrame.maxX - win.frame.width - 16, max(screen.visibleFrame.minX + 16, x - win.frame.width / 2)), y: max(screen.visibleFrame.minY + 16, panel.frame.minY - win.frame.height - 8)))
        } else { win.center() }
        win.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [weak win] in
            func textView(_ root: NSView) -> NoteTextView? {
                if let view = root as? NoteTextView { return view }
                return root.subviews.lazy.compactMap { textView($0) }.first
            }
            if let root = win?.contentView, let view = textView(root) { win?.makeFirstResponder(view) }
        }
    }
    func finishEditor(_ id: UUID) {
        guard let entry = editors.removeValue(forKey: id) else { return }
        presentation.detached.remove(id)
        entry.session.cancelPending(); entry.window.close(); show()
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard let entry = editors.values.first(where: { $0.window === sender }) else { return true }
        return entry.session.flush(store)
    }
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let id = editors.first(where: { $0.value.window === window })?.key else { return }
        presentation.detached.remove(id)
        editors.removeValue(forKey: id)?.session.cancelPending()
    }

}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
