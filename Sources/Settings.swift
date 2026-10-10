import Cocoa
import SwiftUI

// Preferences describe display and defaults; existing note contents stay independent.
enum NotePreferences {
    static var font: NSFont {
        let size = UserDefaults.standard.object(forKey: "noteFontSize") as? Double ?? 17
        switch UserDefaults.standard.string(forKey: "noteFont") ?? "system" {
        case "rounded": return NSFont(descriptor: NSFont.systemFont(ofSize: size).fontDescriptor.withDesign(.rounded)!, size: size) ?? .systemFont(ofSize: size)
        case "mono": return .monospacedSystemFont(ofSize: size, weight: .regular)
        default: return .systemFont(ofSize: size)
        }
    }
    static func imageWidth(available: CGFloat) -> CGFloat {
        UserDefaults.standard.string(forKey: "imageSizing") == "fit" ? available : min(available, 320)
    }
}
private enum SettingsPage: String, CaseIterable, Identifiable {
    case general = "通用", notes = "便笺", shortcuts = "快捷键", data = "数据与关于"
    var id: String { rawValue }
    var icon: String { switch self { case .general: return "gearshape"; case .notes: return "note.text"; case .shortcuts: return "keyboard"; case .data: return "tray" } }
    var tint: Color { switch self { case .general: return .gray; case .notes: return .orange; case .shortcuts: return .blue; case .data: return .green } }
}
struct SettingsGroup<Content: View>: View {
    let title: String
    var caption: String = ""
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary).padding(.leading, 12)
            VStack(spacing: 0, content: content).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.primary.opacity(0.06), lineWidth: 1))
            if !caption.isEmpty { Text(caption).font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).padding(.horizontal, 12) }
        }
    }
}
struct SettingRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        HStack(spacing: 16) { Text(title).font(.system(size: 13)); Spacer(minLength: 12); content() }
            .padding(.horizontal, 14).frame(minHeight: 44)
    }
}
struct SettingsView: View {
    @ObservedObject var store: Store
    @State private var page: SettingsPage = .general
    @AppStorage("hoverReveal") private var hoverReveal = true
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("defaultPinned") private var defaultPinned = false
    @AppStorage("defaultColor") private var defaultColor = 0
    @AppStorage("noteFont") private var noteFont = "system"
    @AppStorage("noteFontSize") private var noteFontSize = 17.0
    @AppStorage("markdownEnabled") private var markdownEnabled = true
    @AppStorage("imageSizing") private var imageSizing = "fixed"
    @State private var result = ""
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("设置").font(.system(size: 20, weight: .semibold)).padding(.horizontal, 12).padding(.top, 18).padding(.bottom, 20)
                ForEach(SettingsPage.allCases) { item in
                    Button { page = item } label: {
                        HStack(spacing: 10) {
                            Image(systemName: item.icon).font(.system(size: 12, weight: .medium)).foregroundStyle(.white)
                                .frame(width: 25, height: 25).background(item.tint, in: RoundedRectangle(cornerRadius: 6))
                            Text(item.rawValue).font(.system(size: 13)); Spacer()
                        }.padding(9).contentShape(Rectangle())
                            .background(page == item ? Color.accentColor.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 7))
                    }.buttonStyle(.plain).accessibilityAddTraits(page == item ? .isSelected : [])
                }
                Spacer()
                Text("绳上便笺").font(.system(size: 11)).foregroundStyle(.secondary).padding(12)
            }.padding(.horizontal, 10).frame(width: 160).background(Color(nsColor: .windowBackgroundColor))
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(page.rawValue).font(.system(size: 21, weight: .semibold)).padding(.bottom, 2)
                    switch page {
                    case .general: general
                    case .notes: notes
                    case .shortcuts: shortcuts
                    case .data: data
                    }
                }.padding(28).frame(maxWidth: .infinity, alignment: .leading)
            }.background(Color(nsColor: .underPageBackgroundColor))
        }.frame(minWidth: 680, minHeight: 500)
    }
    private var general: some View {
        VStack(spacing: 22) {
            SettingsGroup(title: "展开与收起", caption: "关闭悬停展开后，仍可点击菜单栏图标或使用全局快捷键。") {
                SettingRow(title: "悬停菜单栏时展开") { Toggle("悬停菜单栏时展开", isOn: $hoverReveal).labelsHidden().toggleStyle(.switch).controlSize(.small) }
            }
            SettingsGroup(title: "窗口", caption: "只影响新建便笺。已有便笺可通过图钉单独调整。") {
                SettingRow(title: "新便笺默认置顶") { Toggle("新便笺默认置顶", isOn: $defaultPinned).labelsHidden().toggleStyle(.switch).controlSize(.small) }
            }
            SettingsGroup(title: "动效", caption: "系统开启「减少动态效果」时，也会自动减少动画。") {
                SettingRow(title: "减少摆动和滑入动画") { Toggle("减少摆动和滑入动画", isOn: $reduceMotion).labelsHidden().toggleStyle(.switch).controlSize(.small) }
            }
        }
    }
    private var notes: some View {
        VStack(spacing: 22) {
            SettingsGroup(title: "文字", caption: "立即应用到打开的便笺及之后打开的便笺。") {
                SettingRow(title: "字体") {
                    Picker("字体", selection: $noteFont) { Text("系统字体").tag("system"); Text("圆体").tag("rounded"); Text("等宽字体").tag("mono") }.labelsHidden().frame(width: 150)
                }
                Divider().padding(.leading, 14)
                SettingRow(title: "字号") {
                    Picker("字号", selection: $noteFontSize) { ForEach([14.0, 17, 20, 24], id: \.self) { Text("\(Int($0)) 点").tag($0) } }.labelsHidden().frame(width: 150)
                }
                Text("把眼前的小事，挂在绳子上。\nA little space for your thoughts.")
                    .font(Font(NotePreferences.font)).lineSpacing(6).frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    .background(papers[max(0,min(3,defaultColor))]).foregroundStyle(.black.opacity(0.8)).clipShape(RoundedRectangle(cornerRadius: 6)).padding(12)
            }
            SettingsGroup(title: "编辑", caption: "支持标题、粗体、斜体、删除线、代码、引用和列表。当前行显示语法标记，其他行显示排版；原文完整保存。") {
                SettingRow(title: "Markdown 即时排版") { Toggle("Markdown 即时排版", isOn: $markdownEnabled).labelsHidden().toggleStyle(.switch).controlSize(.small) }
            }
            SettingsGroup(title: "新便笺", caption: "默认纸色仅用于新建便笺。") {
                SettingRow(title: "默认纸色") {
                    Picker("默认纸色", selection: $defaultColor) {
                        ForEach(0..<4) { Text(["奶黄色", "鼠尾草绿", "桃粉色", "雾蓝色"][$0]).tag($0) }
                    }.labelsHidden().frame(width: 150)
                }
            }
            SettingsGroup(title: "图片", caption: "新图片的初始宽度。插入后可拖动图片角点调整，尺寸会单独记住；右键可重新适应窗口。") {
                SettingRow(title: "显示方式") {
                    Picker("图片显示方式", selection: $imageSizing) { Text("固定宽度").tag("fixed"); Text("适应便笺宽度").tag("fit") }.labelsHidden().frame(width: 150)
                }
            }
        }
    }
    private var shortcuts: some View {
        VStack(spacing: 22) {
            SettingsGroup(title: "全局快捷键", caption: "点按后录入组合键；⌫ 清除，Esc 取消。冲突时保留原设置。") { ShortcutSettings().padding(14) }
            SettingsGroup(title: "便笺内快捷键", caption: "以下为固定快捷键，仅在应用内生效。") {
                SettingRow(title: "新建便笺") { Text("⌘N").foregroundStyle(.secondary) }
                Divider().padding(.leading, 14)
                SettingRow(title: "查找正文") { Text("⌘F").foregroundStyle(.secondary) }
                Divider().padding(.leading, 14)
                SettingRow(title: "保存并关闭") { Text("Esc / ⌘↩").foregroundStyle(.secondary) }
                Divider().padding(.leading, 14)
                SettingRow(title: "撤销 / 重做") { Text("⌘Z / ⇧⌘Z").foregroundStyle(.secondary) }
            }
        }
    }
    private var data: some View {
        VStack(spacing: 22) {
            SettingsGroup(title: "本地数据", caption: "备份包含文字、图片、归档、草稿和回收站。导入时合并新增便笺，同一张便笺保留本机版本。") {
                SettingRow(title: "完整备份") { Button("导出…", action: export) }
                Divider().padding(.leading, 14)
                SettingRow(title: "从备份恢复") { Button("导入…", action: importBackup) }
                Divider().padding(.leading, 14)
                SettingRow(title: "存储位置") { Button("在访达中打开") { NSWorkspace.shared.open(store.file.deletingLastPathComponent()) } }
            }
            if !result.isEmpty { Text(result).font(.system(size: 12)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
            SettingsGroup(title: "关于") {
                HStack(spacing: 14) {
                    Image(nsImage: Brand.appIcon(size: 48)).frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 5) { Text("绳上便笺").font(.headline); Text("版本 0.10.0 · 原生 macOS 应用").font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                }.padding(16)
            }
            Text("内容保存在这台 Mac 上，没有自动云同步。").font(.system(size: 11)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    private func export() {
        let panel = NSSavePanel(); panel.allowedContentTypes = [.json]; panel.nameFieldStringValue = "绳上便笺备份.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; try encoder.encode(store.book).write(to: url, options: .atomic); result = "备份已导出，包含全部文字和图片。" }
            catch { result = "导出失败：\(error.localizedDescription)" }
        }
    }
    private func importBackup() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do { let count = try store.importBackup(Data(contentsOf: url)); result = "已导入 \(count) 张便笺。本机已有的便笺保持不变。" }
            catch { result = "导入失败，未更改便笺。请检查备份文件。" }
        }
    }
}
