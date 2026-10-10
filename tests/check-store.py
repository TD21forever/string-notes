from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parents[1]
checks = r'''
import Cocoa
func check(_ value: @autoclosure () -> Bool, _ name: String) { if !value() { fatalError(name) }; print("PASS: " + name) }
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let folder = root.appendingPathComponent("normal")
let store = Store(folder: folder, seedWelcome: false)
let a = Memo(text: "中文便笺\n第二行", color: 3)
check(store.draft(a), "write draft")
check(Store(folder: folder, seedWelcome: false).drafts == [a], "draft survives restart")
check(store.put(a) && store.drafts.isEmpty, "publish clears draft")
check(store.draft(a) && store.drafts.isEmpty, "unchanged edit creates no draft")
var b = Memo(text: "完成", color: 1, done: true)
check(store.put(b) && store.active == [a], "archive separated from line")
check(store.delete(a.id) && store.active.isEmpty, "soft delete")
let reopened = Store(folder: folder, seedWelcome: false)
check(reopened.restore() && reopened.notes.first == a, "trash survives restart and restores position")
check(reopened.move(a.id, to: b.id) && reopened.notes.last == a, "reorder")
check(reopened.undoOrder() && reopened.notes.first == a, "undo reorder")
var changed = a; changed.text = "草稿不是已发布内容"
check(reopened.draft(changed) && reopened.notes.first == a, "draft isolation")
check(reopened.discardDraft(a.id) && reopened.notes.first == a, "discard preserves published note")
let legacy = root.appendingPathComponent("legacy")
try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
let old = try JSONEncoder().encode([a,b])
try old.write(to: legacy.appendingPathComponent("notes.json"))
let migration = Store(folder: legacy, seedWelcome: false)
check(migration.notes == [a,b], "legacy notes loaded")
check(try Data(contentsOf: legacy.appendingPathComponent("notes-before-v3.json")) == old, "legacy backup preserved")
check(migration.put(a) && Store(folder: legacy, seedWelcome: false).notes == [a,b], "schema migration and reload")
let corrupt = root.appendingPathComponent("corrupt")
try FileManager.default.createDirectory(at: corrupt, withIntermediateDirectories: true)
let invalid = Data("broken json".utf8)
try invalid.write(to: corrupt.appendingPathComponent("notes.json"))
let bad = Store(folder: corrupt, seedWelcome: false)
check(!bad.put(a), "corrupt storage blocks writes")
check(try Data(contentsOf: bad.file) == invalid, "corrupt original untouched")
let failed = Store(folder: root.appendingPathComponent("failed"), seedWelcome: false)
try FileManager.default.createDirectory(at: failed.file, withIntermediateDirectories: true)
check(!failed.put(a) && failed.notes.isEmpty && !failed.error.isEmpty, "failed commit does not publish success")
let welcomeFolder = root.appendingPathComponent("welcome")
let welcome = Store(folder: welcomeFolder)
check(welcome.notes.count == 1 && welcome.notes[0].text.hasPrefix("欢迎使用"), "first launch welcome")
check(Store(folder: welcomeFolder).notes == welcome.notes, "welcome never duplicates")
check(welcome.delete(welcome.notes[0].id) && Store(folder: welcomeFolder).notes.isEmpty, "deleted welcome stays deleted")
changed.staysOnTop = true
check(reopened.autoSave(changed) && Store(folder: folder, seedWelcome: false).notes.first == changed, "autosave and pin survive restart")
check(reopened.draft(a) && reopened.autoSave(changed) && reopened.drafts.isEmpty, "autosave clears stale draft")
check(!failed.autoSave(changed) && failed.notes.isEmpty, "autosave failure does not publish")
let count = reopened.notes.count
check(reopened.autoSave(Memo(text: "  ")) && reopened.notes.count == count, "blank new note is not published")

let picture = NSImage(size: NSSize(width: 640, height: 320), flipped: false) { rect in NSColor.systemBlue.setFill(); rect.fill(); return true }
let rich = NSMutableAttributedString(string: "图片前\n")
rich.append(NoteDocument.image(picture, width: 300)!)
rich.append(NSAttributedString(string: "\n图片后"))
var illustrated = Memo(text: rich.string); illustrated.richText = NoteDocument.encode(rich)
check(illustrated.richText != nil && reopened.autoSave(illustrated), "image note saves atomically")
let restored = Store(folder: folder, seedWelcome: false).notes.first { $0.id == illustrated.id }!
let document = NoteDocument.decode(restored)
let attachment = document.attribute(.attachment, at: 4, effectiveRange: nil) as? NSTextAttachment
check(document.string == rich.string && attachment?.fileWrapper?.regularFileContents != nil, "inline image and text survive restart")
check(reopened.delete(illustrated.id) && reopened.restore(illustrated.id) && reopened.notes.last?.richText == illustrated.richText, "trash restore preserves image bytes")
let exported = try JSONEncoder().encode(reopened.book)
let imported = try JSONDecoder().decode(Notebook.self, from: exported)
check(imported.notes.last?.richText == illustrated.richText, "backup includes image bytes")
let fit = NSTextStorage(attributedString: document); NoteDocument.fitImages(fit, width: 180)
let cell = (fit.attribute(.attachment, at: 4, effectiveRange: nil) as? NSTextAttachment)?.attachmentCell
check(abs((cell?.cellSize().width ?? 0) - 180) < 1, "image fits narrow paper")
check(NoteDocument.preview(illustrated).contains("[图片]"), "image-only preview is readable")

let importStore = Store(folder: root.appendingPathComponent("import"), seedWelcome: false)
let added = try importStore.importBackup(exported)
check(added == imported.notes.count + imported.trash.count, "import merges backup including images")
let duplicateCount = try importStore.importBackup(exported)
check(duplicateCount == 0, "repeated import does not duplicate")
var local = importStore.notes[0]; local.text = "本机较新的修改"; _ = importStore.autoSave(local)
_ = try importStore.importBackup(exported)
check(importStore.notes[0].text == local.text, "import preserves existing local version")
let beforeImport = try Data(contentsOf: importStore.file)
do { _ = try importStore.importBackup(Data("broken".utf8)); fatalError("invalid import accepted") } catch { print("PASS: invalid import rejected") }
let afterImport = try Data(contentsOf: importStore.file)
check(beforeImport == afterImport, "invalid import leaves file untouched")
var wrongVersion = imported; wrongVersion.version = 99
let wrongData = try JSONEncoder().encode(wrongVersion)
do { _ = try importStore.importBackup(wrongData); fatalError("unknown version accepted") } catch { print("PASS: unknown backup version rejected") }

let source = "# 标题 😀\n**加粗** *斜体* ~~删除~~ `**literal**`\n> 引用\n- [x] 完成\n普通正文\n"
let styled = NSTextStorage(string: source)
let baseFont = NSFont.systemFont(ofSize: 17)
MarkdownStyle.apply(styled, selection: NSRange(location: styled.length, length: 0), font: baseFont, enabled: true)
check(styled.string == source, "markdown styling preserves exact Unicode source")
let ns = source as NSString
let headingFont = styled.attribute(.font, at: ns.range(of: "标题").location, effectiveRange: nil) as! NSFont
check(headingFont.pointSize > 17, "heading is visually larger")
let boldFont = styled.attribute(.font, at: ns.range(of: "加粗").location, effectiveRange: nil) as! NSFont
check(NSFontManager.shared.traits(of: boldFont).contains(.boldFontMask), "bold syntax styles body")
check((styled.attribute(.font, at: 0, effectiveRange: nil) as! NSFont).pointSize < 1, "inactive syntax markers collapse")
MarkdownStyle.apply(styled, selection: NSRange(location: 2, length: 0), font: baseFont, enabled: true)
check((styled.attribute(.font, at: 0, effectiveRange: nil) as! NSFont).pointSize == 17, "active line reveals source markers")
let canonical = MarkdownStyle.canonical(styled, font: baseFont)
check(canonical.string == source && (canonical.attribute(.font, at: 0, effectiveRange: nil) as! NSFont).pointSize == 17, "saved source does not inherit hidden markers")
MarkdownStyle.apply(styled, selection: NSRange(location: 0, length: 0), font: baseFont, enabled: false)
check((styled.attribute(.font, at: 2, effectiveRange: nil) as! NSFont).pointSize == 17, "disabling markdown restores plain display")
check(MarkdownStyle.nextListPrefix("- [x] 已完成")?.prefix == "- [ ] ", "task continuation is unchecked")
check(MarkdownStyle.nextListPrefix("12. 项目")?.prefix == "13. ", "numbered list continuation")
check(MarkdownStyle.nextListPrefix("- ")?.empty == true, "empty list can exit")
let illustratedStyle = NSTextStorage(attributedString: rich)
MarkdownStyle.apply(illustratedStyle, selection: NSRange(location: 0, length: 0), font: baseFont, enabled: true)
let imageCanonical = MarkdownStyle.canonical(illustratedStyle, font: baseFont)
check(imageCanonical.attribute(.attachment, at: 4, effectiveRange: nil) != nil, "markdown retains inline image attachment")
let literal = NSTextStorage(string: "```\n**literal**\n```\n")
MarkdownStyle.apply(literal, selection: NSRange(location: literal.length, length: 0), font: baseFont, enabled: true)
check((literal.attribute(.font, at: 4, effectiveRange: nil) as! NSFont).pointSize > 1, "code fence markers remain literal")
let unfinishedCode = "```\nhello\n"
check(MarkdownStyle.codeBlockExit(unfinishedCode, caret: (unfinishedCode as NSString).length) == "```\n", "empty final code line exits with closing fence")
check(MarkdownStyle.codeBlockExit("```\nhello", caret: 9) == nil, "nonempty code line stays in block")
let closedCode = unfinishedCode + "```\n正文"
let afterCode = NSTextStorage(string: closedCode)
MarkdownStyle.apply(afterCode, selection: NSRange(location: afterCode.length, length: 0), font: NSFont.systemFont(ofSize: 17), enabled: true)
check(afterCode.attribute(.backgroundColor, at: afterCode.length - 1, effectiveRange: nil) == nil, "text after closing fence has no code background")
check(MarkdownStyle.codeBlock(at: afterCode.length, in: closedCode) == nil, "typing after closed code block is normal")
check(MarkdownStyle.fencedBlocks("````\n```\ntext").first?.closed == false, "shorter fence does not close longer fence")
check(MarkdownStyle.fencedBlocks("```\n```swift\ntext").first?.closed == false, "closing fence cannot have trailing content")
check(MarkdownStyle.codeBlockExit("普通文字\n", caret: 5) == nil, "normal blank line does not insert fence")

let sized = NoteDocument.resized(attachment!, desiredWidth: 240, available: 500)!
let sizedAttachment = sized.attribute(.attachment, at: 0, effectiveRange: nil) as! NSTextAttachment
check(NoteDocument.preferredWidth(sizedAttachment) == 240, "manual image width is recorded")
let sizedStorage = NSTextStorage(attributedString: sized)
NoteDocument.fitImages(sizedStorage, width: 120)
check(abs(sizedAttachment.attachmentCell!.cellSize().width - 120) < 1 && NoteDocument.preferredWidth(sizedAttachment) == 240, "narrow window preserves preferred image width")
NoteDocument.fitImages(sizedStorage, width: 800)
check(abs(sizedAttachment.attachmentCell!.cellSize().width - 240) < 1, "wide window restores chosen width without enlargement")
let encodedSized = NoteDocument.encode(sizedStorage)!
var imageMemo = Memo(text: sizedStorage.string); imageMemo.richText = encodedSized
let reloadedSized = NoteDocument.decode(imageMemo)
let reloadedAttachment = reloadedSized.attribute(.attachment, at: 0, effectiveRange: nil) as! NSTextAttachment
check(NoteDocument.preferredWidth(reloadedAttachment) == 240, "RTFD roundtrip preserves image sizing metadata")
check(reloadedAttachment.fileWrapper!.regularFileContents == attachment!.fileWrapper!.regularFileContents, "resizing never modifies source pixels")
let fitting = NSTextStorage(attributedString: NoteDocument.resized(attachment!, desiredWidth: 0, available: 300)!)
NoteDocument.fitImages(fitting, width: 450)
let fitted = fitting.attribute(.attachment, at: 0, effectiveRange: nil) as! NSTextAttachment
check(NoteDocument.preferredWidth(fitted) == 0 && abs(fitted.attachmentCell!.cellSize().width - 450) < 1, "explicit fit mode tracks window width")
check(abs(sizedAttachment.attachmentCell!.cellSize().height / sizedAttachment.attachmentCell!.cellSize().width - 0.5) < 0.01, "image resize preserves aspect ratio")

let windowStore = Store(folder: root.appendingPathComponent("windows"), seedWelcome: false)
let hangingStore = Store(folder: root.appendingPathComponent("hanging"), seedWelcome: false)
let hangingA = Memo(text: "挂回 A"), hangingB = Memo(text: "挂回 B"), hangingC = Memo(text: "挂回 C")
_ = hangingStore.put(hangingA); _ = hangingStore.put(hangingB); _ = hangingStore.put(hangingC)
check(hangingStore.place(hangingA.id, before: nil) && hangingStore.notes.map(\.id) == [hangingB.id, hangingC.id, hangingA.id], "rope drop supports end insertion")
check(hangingStore.place(hangingA.id, before: hangingB.id) && hangingStore.notes.map(\.id) == [hangingA.id, hangingB.id, hangingC.id], "rope drop inserts before target")
check(hangingStore.undoOrder() && hangingStore.notes.last?.id == hangingA.id, "rope reorder can undo")
check(!hangingStore.place(hangingA.id, before: UUID()) && hangingStore.notes.count == 3, "invalid rope destination preserves notes")
let sessionA = EditSession(Memo(text: "A"))
let sessionB = EditSession(Memo(text: "B"))
check(sessionA.flush(windowStore) && sessionB.flush(windowStore) && windowStore.notes.count == 2, "independent editor sessions persist separate notes")
sessionA.note.text = "A changed"; sessionB.note.text = "B changed"
check(sessionB.flush(windowStore) && sessionA.flush(windowStore) && windowStore.notes.first(where: { $0.id == sessionB.note.id })?.text == "B changed", "interleaved autosave preserves other window changes")
sessionA.cancelPending()
sessionB.note.text = "B still editable"
check(sessionB.flush(windowStore) && windowStore.notes.count == 2, "closing one session leaves other editable")
check(windowStore.delete(sessionA.note.id) && sessionB.flush(windowStore) && windowStore.notes.count == 1 && windowStore.notes[0].id == sessionB.note.id, "deleting one session preserves other note")

'''
# Throwing reads are evaluated before the nonthrowing check autoclosure.
checks = checks.replace('check(try Data(contentsOf: legacy.appendingPathComponent("notes-before-v3.json")) == old,', 'let backup = try Data(contentsOf: legacy.appendingPathComponent("notes-before-v3.json")); check(backup == old,').replace('check(try Data(contentsOf: bad.file) == invalid,', 'let corruptAfter = try Data(contentsOf: bad.file); check(corruptAfter == invalid,')
with tempfile.TemporaryDirectory(prefix='string-notes-test-') as folder:
    path = Path(folder)
    (path / 'main.swift').write_text(checks)
    app_source = (root / 'Sources/main.swift').read_text()
    session_source = app_source[app_source.index('final class EditSession:'):app_source.index('final class NoteHostingView')]
    (path / 'EditSession.swift').write_text('import Foundation\nimport Combine\n' + session_source)
    subprocess.run(['xcrun','swiftc','-module-cache-path','/tmp/string-notes-module-cache',str(root/'Sources/Store.swift'),str(root/'Sources/NoteDocument.swift'),str(root/'Sources/Markdown.swift'),str(path/'EditSession.swift'),str(path/'main.swift'),'-o',str(path/'test')],check=True)
    subprocess.run([str(path/'test'),str(path/'data')],check=True)
