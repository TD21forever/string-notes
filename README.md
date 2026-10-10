<p align="center"><img src="Assets/app-icon.png" width="128" alt="绳上便笺"></p>

# 绳上便笺 · String Notes

把眼前的小事，挂在绳子上。

原生 macOS 菜单栏便笺。鼠标停在菜单栏片刻，一根细绳带着纸条滑下来；点开记录，写下自动保存，完成后收进便笺盒。使用 Swift、SwiftUI 和 AppKit，没有网页容器。

## 安装

当前提供 **Apple Silicon（M 系列）测试版**，最低构建目标为 macOS 13 Ventura。最低版本设备兼容性尚未实机验证。Intel 版尚未发布。

```bash
brew install --cask TD21forever/tap/string-notes
```

也可从 [v0.10.0 发布页](https://github.com/TD21forever/string-notes/releases/tag/v0.10.0) 下载 ZIP，解压后将「绳上便笺.app」拖到「应用程序」。

此测试版只有 ad-hoc 签名，**尚未取得 Developer ID 签名及 Apple 公证**，macOS 可能阻止首次启动。如果系统支持，可通过访达右键「打开」或「系统设置 → 隐私与安全性」中的正常授权入口允许自己信任的应用。不要关闭 Gatekeeper；若无法正常授权，请等待公证版本或自行构建。

升级：

```bash
brew update
brew upgrade --cask TD21forever/tap/string-notes
```

## 可以做什么

- 透明绳子悬浮层，空白区域不拦截下层应用。
- 彩色便笺、多窗口、单张置顶，拖动夹子调整顺序。
- 自动保存，关闭和退出补存；保存失败保留窗口或阻止退出。
- 原生正文编辑、查找、撤销/重做、字体和字号设置。
- Markdown 即时排版：标题、强调、代码、引用、列表和任务文本；未实现点击式任务复选框或完整 CommonMark。
- 粘贴/插入图片，独立调整图片尺寸，保留原始图片数据。
- 搜索便笺盒，归档和回收站恢复。
- 四组可自定义全局快捷键，通过 Carbon 注册，不要求辅助功能权限。
- JSON 完整备份导出与合并导入，包含图片和回收站。
- 可关闭悬停展开，遵循应用及系统的减少动态效果设置。

## 快速上手

点击菜单栏的绳上纸条图标展开，或将鼠标停在菜单栏片刻。点绳子旁的「＋」新建，点纸条编辑。右键菜单栏图标打开所有便笺、设置或退出。

正文中 Return 换行，⌘F 查找，⌘Z 撤销，⇧⌘Z 重做；Esc 先关闭查找栏，再保存关闭便笺，⌘Return 保存关闭。⌘N 新建，⌘, 打开设置。

全局快捷键默认是 ⌃⌥⌘N 新建、⌃⌥⌘A 所有便笺、⌃⌥⌘L 归档、⌃⌥⌘S 展开/收起，可在设置录入新组合或清除。

## 数据与备份

便笺保存在 `~/Library/Application Support/StringNotes/notes.json`，没有账户或自动云同步。图片以 RTFD 附件包含在数据文件内。设置使用本机 UserDefaults。

写入采用原子替换；损坏文件或未知数据版本会阻止覆盖。旧版数组数据首次读取时保留 `notes-before-v3.json`。设置里的导出包含文字、图片、归档、草稿和回收站；导入只合并新 ID，同 ID 保留本机版本，**不是覆盖式回滚**。

请定期导出备份。普通 `brew uninstall --cask string-notes` 只卸载应用，Cask 不配置删除便笺数据的 zap 动作。

## 构建与测试

安装 Xcode Command Line Tools 后：

```bash
./build.sh
python3 tests/check-store.py
./scripts/package.sh
```

发布版本由 `VERSION` 决定。默认构建 arm64，设置 `STRING_NOTES_ARCH=x86_64` 可尝试 Intel 构建；本次发行不包含未经验证的 Intel 产物。

图标重新生成：`./scripts/build-icons.sh`。构建输出在 `build/`，发行 ZIP 和 SHA256 在 `dist/`。GitHub Actions 执行隔离测试和打包；推送与 `VERSION` 匹配的 `v*` 标签可生成测试版 Release。Tap 的版本与校验和需同步更新。

## 测试版范围

存储、备份合并、损坏数据保护、图片持久化及缩放、Markdown、拖动排序数据逻辑和多编辑会话有隔离测试。此次发布不代表所有界面操作均已验收。

仍需在不同 macOS、显示器、中文输入法和 Space 上继续验证。当前没有自动云同步、自动版本历史、应用内自动更新或公证发行包。请通过 [Issues](https://github.com/TD21forever/string-notes/issues) 反馈系统版本、复现步骤和现象，避免上传私人便笺。

## License and acknowledgements

本项目代码使用 MIT License。绳子、金属夹子与透明悬浮层参考并改编自 [Tendedero](https://github.com/alejandrobujan/tendedero)，部分编辑行为参考 [Noty](https://github.com/aimen08/noty)；第三方声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。使用独立名称和自绘图标。

Telegram macOS 客户端仅用于交互研究，没有复制其 GPL 源码或引入其框架。
