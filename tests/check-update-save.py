from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[1]
source=(root/'Sources/main.swift').read_text()
session=source[source.index('final class EditSession:'):source.index('final class NoteHostingView')]
termination=source[source.index('    func applicationShouldTerminate('):source.index('    @objc func findNote()')]
# Inspect cancellation without showing a modal alert in the isolated test process.
termination=termination.replace('alert.runModal()', '_ = alert.messageText')
with tempfile.TemporaryDirectory(prefix='string-notes-update-save-') as folder:
 path=Path(folder)
 (path/'Session.swift').write_text('import Foundation\nimport Combine\n'+session)
 (path/'main.swift').write_text('''import Cocoa
func check(_ result: Bool, _ name: String) { precondition(result, name); print("PASS: " + name) }
final class Delegate {
 let store = Store(folder: URL(fileURLWithPath: CommandLine.arguments[1]), seedWelcome: false)
 var editors: [UUID: (window: NSWindow, session: EditSession)] = [:]
'''+termination+'''
}
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let delegate = Delegate()
let note = Memo(text: "Pending 中文 before restart")
let session = EditSession(note)
let window = NSWindow(contentRect: NSRect(x:0,y:0,width:400,height:300),styleMask:[.titled],backing:.buffered,defer:false)
window.isReleasedWhenClosed = false
delegate.editors[note.id] = (window,session)
check(delegate.applicationShouldTerminate(app) == .terminateNow, "quit flushes unsaved editor before updater replaces app")
check(Store(folder: URL(fileURLWithPath: CommandLine.arguments[1]),seedWelcome:false).notes.first?.text == note.text, "flushed note survives relaunch")
session.note.text = "do not lose this"
session.encodingFailed = true
check(delegate.applicationShouldTerminate(app) == .terminateCancel, "encoding failure blocks updater termination")
check(session.note.text == "do not lose this", "failed update save preserves live editor")
session.encodingFailed = false
let text = NSTextView(frame: NSRect(x:0,y:0,width:300,height:200))
window.contentView = text; window.makeFirstResponder(text)
text.setMarkedText("pinyin", selectedRange: NSRange(location:6,length:0), replacementRange:NSRange(location:NSNotFound,length:0))
check(text.hasMarkedText(), "fixture has active input-method composition")
check(delegate.applicationShouldTerminate(app) == .terminateCancel, "active composition blocks updater termination")
text.unmarkText()
try FileManager.default.removeItem(at: delegate.store.file)
try FileManager.default.createDirectory(at: delegate.store.file,withIntermediateDirectories:false)
check(delegate.applicationShouldTerminate(app) == .terminateCancel, "disk write failure blocks updater termination")
window.orderOut(nil)
''')
 subprocess.run(['xcrun','swiftc','-module-cache-path','/tmp/string-notes-module-cache',str(root/'Sources/Store.swift'),str(root/'Sources/Localization.swift'),str(path/'Session.swift'),str(path/'main.swift'),'-o',str(path/'test')],check=True)
 result=subprocess.run([str(path/'test'),str(path/'data')],check=True,capture_output=True,text=True)
 print(result.stdout,end='')
 assert 'disk write failure blocks' in result.stdout, result.stderr
