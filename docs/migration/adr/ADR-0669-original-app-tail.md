# ADR-0669 app__ 族尾部收口：快捷方式标签 + 共享打开 500MB 上限 + 平台边界登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：721
- 证据：`docs/migration/evidence/original-app-tail-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-app-tail.mjs`

## 背景

`app__` 族是原版 application-scope 顶层字符串集合（40 键），包括启动器快捷
方式标签、PDF 打开错误、更新/评分/登出/账号删除提示、键盘快捷键组标题、
新窗口错误、native 库缺失错误等。审计将族内键分为三类处理。

## 决策

### 1. 逐字对齐（已实现）

- `shortcut_new_note`：Harmony `"New note"` → `"New Note"`（原版
  `app__shortcut_new_note` 为大写 N）。
- `shortcut_new_photo`：`"New photo note"` → `"New Photo"`（原版
  `app__shortcut_new_photo` 为 "New Photo"；zh 同步调整为 `新建照片`）。
- 共享打开大小上限：原版 `jv5.f(..., flag16)` 对打开路径施加
  `524288000` 字节（500MB）上限并归 `gr9.TooLarge`。Harmony 新增
  `SHARED_OPEN_MAX_BYTES = 524288000` 与 `ImportResult.TOO_LARGE`，
  `importSharedUris` 在分发前对 uri 做 `statSync` 预检，超限直接返回
  `TOO_LARGE`（不进导入详情表，与原版 resolve 期拦截一致）。
- `importSharedAndOpen` 失败 toast 分类：`TOO_LARGE` →
  `open_pdf_too_large`（"This PDF is too large to import"）；其余非取消
  失败 → `open_pdf_failed`（"Couldn't open this PDF"）。对应原版
  `vs8` 的 `app__open_pdf_too_large` / `app__open_pdf_failed` 映射。

### 2. 超集偏差（已保留并登记）

- 原版对密码保护 PDF 仅 toast `app__open_pdf_password_protected`；
  Harmony 已有 `pdfPasswordPrompt` 交互式密码输入流程（早于本 phase
  实现），功能上强于原版提示，保留不重退。

### 3. 平台/生态边界（fail-closed 登记，无 Harmony 对应实现）

- `update_required` / `update_ready` / `later` / `restart` / `update` /
  `failed_to_launch_store`：原版为 Google Play In-App Update 流程
  （`AppUpdateManager`），依赖 Play 服务与 Play 商店分发通道；
  HarmonyOS 分发与更新由 AppGallery 系统侧托管，无等价 in-app 强制
  更新 API。fail-closed。
- `app_rating_*`：原版评分引导走 Play In-App Review API；HarmonyOS
  无应用内评分 API（仅有商店页面跳转，且当前无上架账号场景）。
  fail-closed。
- `account_deletion_notice` / `force_logout` / `login_required_for_photo` /
  `note_limit_share`：均绑定原版后端账号体系（Notability Cloud /
  Ginger Labs 账号），Harmony 端无账号实现——已由 ADR-0662
  （feature_login__/feature_paywall__ fail-closed）统一登记，
  本 ADR 将其显式列入 `app__` 族覆盖清单。
- `kbd_shortcut_*` 导航/窗口组：Android 系统 `KeyboardShortcutGroup`
  帮助面板项，HarmonyOS 无系统级快捷键帮助界面——同 ADR-0667
  （ui_text__ 键盘组）登记。
- `error_could_not_open_new_window` / `open_in_new_window`：Android
  多窗口（freeform/多实例）；HarmonyOS 手机形态不支持应用多窗口，
  `open_in_new_window` 菜单项此前已登记不可移植
  （LibraryPage 注释 + ADR-0532 体系），本 ADR 将错误串纳入登记。
- `missing_native_library`：Android `.so` 原生库加载失败提示；
  HarmonyOS 无对等的运行时动态库缺失场景（Native 库由 HAP 打包
  完整性保证），fail-closed。
- `shortcut_recent_note_long`（"%1$s · %2$s"）/ `shortcut_unfiled` /
  `shortcut_untitled_note`：Android 动态 shortcut（`ShortcutManager`
  `setDynamicShortcuts`）所需的最近笔记/未归档快捷项——依赖运行时
  动态注册与上下文数据，Harmony `shortcuts_config.json` 静态声明
  体系无动态入口，fail-closed（静态两项已逐字对齐）。

### 4. app_widgets__ 族

经审计 `app_widgets__*`（20 键）已全部覆盖：Harmony Form 体系
（forms_config.json + 各 FormFeed/Card/EditAbility）+ ADR-0632 及
d05 系列 replay 已登记；`*_login_required` 项随 ADR-0662 账号边界
fail-closed。本 ADR 一并登记该族收口，无新增代码。

## 影响

- `NoteImporter.ets`：新增 `ImportResult.TOO_LARGE` 与
  `SHARED_OPEN_MAX_BYTES`；`importSharedUris` 入口预检。通用
  `ZIP_MAX_ARCHIVE_BYTES`（1GB）上限保持不变——`.note`/zip 归档
  导入与 PDF 打开上限是原版两条独立路径。
- `LibraryPage.ets`：共享打开失败 toast 改分类映射。
- 资源：en `shortcut_new_note`/`shortcut_new_photo` 改值 +
  新增 `open_pdf_too_large`/`open_pdf_failed`；zh 同步。
- 其余 `app__` 键经登记为平台边界，不产生运行时差异。

## 验证

- `d02-original-app-tail.mjs` 33 断言全绿。
- 全量 Desktop Replay 604/604 全绿。
- clean + `note@ohosTest` + `note@default` 双 HAP 构建通过。
