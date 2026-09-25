# 原版证据：app__ 族尾部 — JADX 静态审计（2026-09-25）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
（JADX 反编译 Notability 1.0.3，只读证据）

## 1. 快捷方式标签（values/strings.xml 原文）

```xml
<string name="app__shortcut_new_note">New Note</string>
<string name="app__shortcut_new_photo">New Photo</string>
<string name="app__shortcut_recent_note_long">%1$s · %2$s</string>
<string name="app__shortcut_unfiled">Unfiled</string>
<string name="app__shortcut_untitled_note">Untitled</string>
```

- `shortcut_new_note` / `shortcut_new_photo`：静态启动器快捷项，
  声明于 `res/xml/shortcuts*.xml`，对应 Harmony
  `shortcuts_config.json` 的 `new_note` / `new_photo` 项。
- `shortcut_recent_note_long` / `shortcut_unfiled` /
  `shortcut_untitled_note`：`ShortcutManager` 动态快捷项
  （最近笔记 "%1$s · %2$s" 标题模板、未归档、默认标题占位），
  运行时按上下文注册——Harmony 静态声明体系无对应入口。

## 2. PDF/打开路径大小上限（jv5.java）

`jv5.f(...)` 打开路径：

- 传入 `flag16` → 默认上限解析为 `524288000L`（=500MB）。
- 先经 ContentResolver 元数据取 size：超限直接返回 TooLarge 结果
  （不进入读取/导入流程）。
- 流式拷贝路径二次执行同一上限（防御元数据缺失场景）。
- 非 flag16 路径走不同的默认上限（10MB 系导入场景），即原版对
  "打开"与"导入"两条路径使用独立阈值。

`vs8.java` 状态映射（`gr9` 枚举 → 资源）：

- `TooLarge` → `app__open_pdf_too_large`
  （"This PDF is too large to import"）
- `PasswordProtected` → `app__open_pdf_password_protected`
  （"This PDF is password protected"）
- 其余失败 → `app__open_pdf_failed`（"Couldn't open this PDF"）

Harmony 对照：`SharedFileIngress` 排队 VIEW/SEND URI →
`LibraryPage.importSharedAndOpen` → `NoteImporter.importSharedUris`
→ 统一导入管线。本 phase 在 `importSharedUris` 分发前加
`statSync` 预检（>524288000 → `ImportResult.TOO_LARGE`），
并在 `importSharedAndOpen` 按结果分类 toast（TooLarge→
`open_pdf_too_large`，其余→`open_pdf_failed`）。密码保护项
Harmony 已由 `pdfPasswordPrompt` 交互流程覆盖（超集）。

## 3. 平台边界项（strings.xml 原文 + 宿主类）

- `app__update_required` / `update_ready` / `later` / `restart` /
  `update` / `failed_to_launch_store`：Google Play In-App Update
  （`AppUpdateManager` / `AppUpdateInfo` 流程），Play 分发专属。
- `app__app_rating_*`（rate_this_app / enjoy / feedback 系）：
  Play In-App Review（`ReviewManager`），无 Harmony 等价。
- `app__account_deletion_notice` / `force_logout` /
  `login_required_for_photo` / `note_limit_share`：Notability
  Cloud 账号体系绑定，随 ADR-0662 登记。
- `app__kbd_shortcut_*`（导航/窗口分组标题）：`hke.java`/`kmi.java`
  构建 `KeyboardShortcutGroup` 供 Android 系统快捷键帮助面板消费，
  同 ADR-0667 登记的 ui_text__ 键盘组。
- `app__error_could_not_open_new_window` / `open_in_new_window`：
  Android freeform 多窗口；`vs8`/`nq7` 侧 launchActivityInNewWindow
  调用点。Harmony 手机形态不支持。
- `app__missing_native_library`：`.so` 加载失败告警
  （System.loadLibrary 失败回退提示），HAP 打包完整性下无对等场景。

## 4. 结论

- 可移植项：快捷方式两静态标签（逐字对齐）+ 共享打开 500MB
  上限与失败分类提示（本 phase 实现）。
- 超集偏差：密码保护 PDF 用交互式密码输入替代原版 toast。
- 其余键均为 Android 平台/生态专属，fail-closed 登记于
  ADR-0669。
