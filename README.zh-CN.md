<p align="center">
  <img src="Assets/app-icon.png" width="120" alt="绳上便笺图标">
</p>

<h1 align="center">绳上便笺 · String Notes</h1>

<p align="center"><a href="README.md">English</a> · <strong>简体中文</strong></p>

<p align="center"><strong>把眼前的小事，挂在绳子上。</strong></p>

<p align="center">
  原生 macOS 菜单栏便笺，让待办、灵感和随手记的小事留在眼前。
</p>

<p align="center">
  <a href="https://github.com/TD21forever/string-notes/releases/tag/v0.13.1"><img src="https://img.shields.io/badge/version-0.13.1-e5b85b" alt="0.13.1"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-555555" alt="macOS 13 及以上构建目标">
  <img src="https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-arm64%20%7C%20x86__64-555555" alt="Apple Silicon + Intel">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-7d9575" alt="MIT License"></a>
</p>

<p align="center">
  <a href="#安装">安装</a> ·
  <a href="#开始使用">开始使用</a> ·
  <a href="#数据与备份">数据与备份</a> ·
  <a href="https://github.com/TD21forever/string-notes/issues">反馈问题</a>
</p>

鼠标停在菜单栏片刻，一根细绳带着彩色纸条滑下来。点开一张，记下刚想到的事；拖动夹子，换个顺序；做完了，就把它收进归档。需要专注时，收起绳子。

绳上便笺使用 **Swift、SwiftUI 和 AppKit** 构建。无需账户，便笺和图片保存在本机。

## 看看实际操作

[![绳上便笺演示：在真实 macOS 桌面上取下便笺、查看内容，再挂回绳子。](Assets/demo/string-notes.gif)](https://github.com/TD21forever/string-notes/raw/refs/heads/main/Assets/demo/string-notes.mp4)

[观看或下载带音乐的完整视频（约 16 秒）](https://github.com/TD21forever/string-notes/raw/refs/heads/main/Assets/demo/string-notes.mp4)。使用真实 Mac 录屏，上方为静音动图预览。[素材署名](Assets/demo/README.md)。

## 一图上手

![绳上便笺真实使用界面：随手记、取下来写、挂回去、放心关](Assets/screenshots/user-guide.zh-CN.jpg)

从左到右，四步把眼前的小事安顿好：

1. **随手记**：点 **＋** 新建，写下小事，输入后自动保存。
2. **取下来写**：向下拖动纸片，松手打开独立窗口；单击也能打开。
3. **挂回去**：拖窗口顶部空白处到绳子，卡片让出位置，松手保存并收起。
4. **放心关**：点图钉保持最前，按 **Esc** 保存并关闭，做完的事收进归档。

## 为什么把便笺挂起来

| | 绳上便笺可以做什么 |
| --- | --- |
| **留在眼前** | 彩色纸条挂在透明绳子上，沿绳拖动可自由摆放并记住位置，向下拖动可取下，再拖回绳上挂好；悬浮层空白区域不阻挡下方应用。 |
| **随手记下** | 菜单栏或全局快捷键打开便笺，输入后自动保存；支持同时打开多张便笺和单张置顶。 |
| **写得顺手** | 原生文本编辑、查找、撤销和重做，字体与字号可调；支持常用 Markdown 排版。 |
| **不只文字** | 粘贴或插入图片，拖动角点调整尺寸，每张图片的尺寸单独保存。 |
| **收好小事** | 便笺盒只保留便笺和归档，搜索更直接；完成后归档，之后随时挂回绳上。 |
| **按你的习惯** | 自定义全局快捷键、关闭悬停展开、减少动态效果；随时导出完整备份。 |

## 安装

提供 **Apple Silicon（M 系列）和 Intel Mac** 安装包，最低构建目标为 **macOS 13 Ventura**。Intel 构建在 GitHub 的 Intel macOS 环境中检查；Intel 实机交互及最低系统版本仍需更多验证。

### 下载 DMG

1. 根据芯片下载 DMG：[Apple Silicon（M 系列）](https://github.com/TD21forever/string-notes/releases/download/v0.13.1/StringNotes-0.13.1-arm64.dmg) 或 [Intel](https://github.com/TD21forever/string-notes/releases/download/v0.13.1/StringNotes-0.13.1-x86_64.dmg)。
2. 打开磁盘映像，将 **绳上便笺.app** 拖到 **Applications（应用程序）**。
3. 从「应用程序」打开。升级时请先退出旧版，再替换应用；已有便笺会保留。

也可下载 [ZIP 安装包](https://github.com/TD21forever/string-notes/releases/download/v0.13.1/StringNotes-0.13.1-arm64.zip)，解压后将应用移到「应用程序」。另提供 [Intel ZIP](https://github.com/TD21forever/string-notes/releases/download/v0.13.1/StringNotes-0.13.1-x86_64.zip)。DMG 和 ZIP 包含相同的应用，[发布页](https://github.com/TD21forever/string-notes/releases/tag/v0.13.1)同时提供 SHA-256 校验文件。

### Homebrew

```bash
brew install --cask TD21forever/tap/string-notes
```

### 首次打开被 macOS 拦截怎么办？

当前版本使用临时签名，尚未取得 Developer ID 签名和 Apple 公证。**无论通过 DMG、ZIP 还是 Homebrew 安装，都可能需要手动放行。**

确认应用来自本项目发布页且你信任它后：

1. 尝试打开应用，在拦截提示中点击「完成」。
2. 进入「系统设置 → 隐私与安全」，找到绳上便笺的拦截提示，点击「仍要打开」。
3. 按 macOS 提示完成确认，再次打开应用。

入口可能因 macOS 版本或设备管理策略而不同，详见 [Apple 官方说明](https://support.apple.com/102445)。无需关闭系统整体的 Gatekeeper。便笺数据独立保存在 `~/Library/Application Support/StringNotes`，替换应用不会删除它们。

<details>
<summary>通过 Homebrew 升级或卸载</summary>

升级：

```bash
brew update
brew upgrade --cask TD21forever/tap/string-notes
```

卸载应用：

```bash
brew uninstall --cask string-notes
```

普通卸载会保留本地便笺数据。此 Cask 没有配置删除用户数据的 `zap` 动作。

</details>

## 开始使用

1. **展开绳子**：点击菜单栏的纸条图标，或将鼠标停在菜单栏片刻。
2. **挂一张便笺**：点击绳子旁的「＋」，写下内容；输入后自动保存。
3. **摆到顺手的位置**：点纸条编辑，沿绳拖动可自由摆放并记住位置；向下拖动便笺可取下，在独立窗口中编辑。拖窗口顶部空白区域回到绳子上即可挂回，关闭取下的窗口也会回到绳上。编辑窗口可以单独置顶。
4. **收好已完成的事**：将便笺归档，以后可在「所有便笺」里搜索、查看或挂回绳上。

右键点击菜单栏图标，可以打开所有便笺、设置或退出应用。

在「设置 → 通用」中：

- **绳子所在的显示器**：默认跟随鼠标，在展开或拖回便笺时选择鼠标所在屏幕；也可选择主显示器或固定某一台显示器。固定屏幕断开后暂用主显示器，重连后自动回到原屏幕。
- **自动收起绳子**：关闭后绳子持续显示，仍可点击菜单栏图标或用快捷键手动收起。

沿绳拖动时，落点不再吸附到固定格子，附近卡片会让位。位置会随显示器宽度调整；卡片较多时可滚动查看，拖到两端也会滚动。摆放位置包含在备份中，可通过菜单栏的「撤销上次排序」撤销最近一次摆放。

<details>
<summary>快捷键</summary>

全局快捷键可在设置中修改或清除，不需要辅助功能权限。

| 操作 | 默认全局快捷键 |
| --- | --- |
| 新建便笺 | ⌃⌥⌘N |
| 所有便笺 | ⌃⌥⌘A |
| 打开归档 | ⌃⌥⌘L |
| 展开 / 收起绳子 | ⌃⌥⌘S |

编辑窗口内：

| 操作 | 快捷键 |
| --- | --- |
| 换行 | Return |
| 查找 | ⌘F |
| 撤销 / 重做 | ⌘Z / ⇧⌘Z |
| 保存并关闭 | ⌘Return |
| 关闭查找栏；未打开查找时保存并关闭 | Esc |
| 新建便笺 | ⌘N |
| 打开设置 | ⌘, |

</details>

<details>
<summary>Markdown 支持范围</summary>

支持标题、强调、代码、引用、列表和任务文本的即时排版。

当前任务列表仅支持文本排版，尚不能点击复选框切换完成状态；也不是完整的 CommonMark 实现。

</details>

## 数据与备份

**便笺保存在你的 Mac 上，无需注册账户，当前没有自动云同步。** 在设置中选择「完整备份 → 导出」，可以一次保存文字、图片、归档和保留的恢复记录。建议在更换设备或尝试新版本前导出一份。

导入备份时，应用会合并新增便笺；遇到相同 ID，会保留本机版本。**导入不是覆盖式恢复，不能用来回滚已有便笺的修改。**

<details>
<summary>存储位置与保存保护</summary>

- 数据文件：`~/Library/Application Support/StringNotes/notes.json`。
- 图片以 RTFD 附件包含在数据文件内，保留原始图片数据；设置保存在本机 UserDefaults 中。
- 数据写入采用原子替换。遇到损坏文件或未知数据版本时，应用会阻止覆盖。
- 关闭编辑窗口和退出应用时会补存；保存失败时保留窗口或阻止退出。
- 旧版数组数据首次迁移时会保留 `notes-before-v3.json`。

</details>

## 测试版与反馈

目前是 **0.13.1**。显示器选择与断开回退、自由摆放与撤销、自动收起策略、存储、备份合并、损坏数据保护、图片持久化与缩放、Markdown、排序数据逻辑和多编辑会话已有隔离测试；单屏原生窗口检查通过，真实外接屏插拔尚未实测；不同 macOS、显示器、中文输入法和 Space 下的界面体验仍需继续验证。

便笺盒现仅保留便笺和归档，恢复草稿合并展示在便笺列表，不再单列草稿或回收站。删除记录仍保存在本地数据和备份中，但当前界面没有恢复入口；可能还会用到的便笺建议归档。

支持中文和 English，默认跟随系统。可在「设置 → 通用 → 语言」选择，重启应用后生效；已有便笺内容不会被翻译。

从菜单栏菜单或「设置 → 数据与关于」选择「检查更新…」。Sparkle 会检查适合当前芯片的正式版本，下载并验证数字签名，随后安装并重新打开应用。退出前保存所有便笺；保存失败或输入法尚在选词时阻止退出。更新后恢复打开的便笺。自动检查可以关闭，安装需要用户确认，手动下载保留为备用入口。

**0.12.0 及更早版本仍需最后手动安装或通过 Homebrew 升级一次**，因为这些版本只有下载链接。装上带新更新器的版本后，后续更新可在应用内完成。Homebrew 安装的应用自更新后，其安装记录可能仍显示旧版本，仍可使用 `brew upgrade --cask TD21forever/tap/string-notes`。此功能不会改变 Apple 公证状态。

当前尚未提供自动云同步、自动版本历史和公证发行包。

遇到问题或有想法，欢迎到 [Issues](https://github.com/TD21forever/string-notes/issues) 留言。反馈时请附上应用版本、macOS 版本、芯片类型和复现步骤；截图请先遮住私人便笺内容。

## 本地开发

<details>
<summary>获取源码、构建与测试</summary>

需要 macOS 和 Xcode Command Line Tools。

```bash
git clone https://github.com/TD21forever/string-notes.git
cd string-notes

# 构建应用
./build.sh

# 运行隔离测试
python3 tests/check-store.py

# 打包发行 ZIP，并生成 SHA256
./scripts/package.sh
```

应用输出在 `build/`，发行文件输出在 `dist/`。版本号由 [VERSION](VERSION) 决定。

默认构建 `arm64`。执行 `STRING_NOTES_ARCH=x86_64 ./scripts/package.sh` 生成 Intel ZIP，再执行 `STRING_NOTES_ARCH=x86_64 ./scripts/package-dmg.sh` 生成对应 DMG。Homebrew 会自动选择匹配芯片的版本。修改图标后可运行 `./scripts/build-icons.sh` 重新生成图标资源。

首次构建会下载固定版本 Sparkle 2.10.0 并校验 SHA-256。[更新签名说明](updates/README.md)介绍本地钥匙串与 GitHub 配置。GitHub Actions 会执行隔离测试、打包并签名更新源。推送与 `VERSION` 匹配的 `v*` 标签会生成 Latest Release；发布后需同步更新 [Homebrew Tap](https://github.com/TD21forever/homebrew-tap) 的版本与校验和。

</details>

## 开源与致谢

绳上便笺使用 [MIT License](LICENSE)，采用独立名称和自绘图标。

感谢 [Tendedero](https://github.com/alejandrobujan/tendedero) 带来的绳子与夹子灵感。项目的绳子、金属夹子和透明悬浮层参考并改编自 Tendedero，部分编辑行为参考 [Noty](https://github.com/aimen08/noty)。相关许可与署名见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
