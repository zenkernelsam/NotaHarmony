# Phase 721 中文报告：`app__` 族尾部收口 — 快捷方式标签对齐 + 共享打开 500MB 上限 + 平台边界登记

## 范围

`app__` 族为原版 application-scope 顶层字符串（40 键）。本 phase 完成
其中可移植项的对齐与其余项的 fail-closed 登记，并顺带收口
`app_widgets__` 族审计（已全覆盖，无新增代码）。

## 原版证据

见 `docs/migration/evidence/original-app-tail-jadx-2026-09-25.md`：

- `jv5.f(..., flag16)`：打开路径上限 `524288000` 字节（500MB），
  元数据预检 + 流式二次执行，超限归 `gr9.TooLarge`。
- `vs8`：`TooLarge` → `app__open_pdf_too_large`；
  `PasswordProtected` → `app__open_pdf_password_protected`；
  其余 → `app__open_pdf_failed`。
- `app__shortcut_new_note` = "New Note"、`app__shortcut_new_photo`
  = "New Photo"（strings.xml 原文）。
- 更新/评分/账号/键盘组/多窗口/native 库键均为 Android 平台专属。

## 变更

### 1. 快捷方式标签逐字对齐

- `shortcut_new_note`："New note" → "New Note"（zh `新建笔记` 不变）。
- `shortcut_new_photo`："New photo note" → "New Photo"；zh
  `新建照片笔记` → `新建照片`（与原版语义一致）。

### 2. 共享打开 500MB 上限（原版 jv5 flag16 路径）

- `NoteImporter.ets` 新增 `SHARED_OPEN_MAX_BYTES = 524288000` 与
  `ImportResult.TOO_LARGE = 5`。
- `importSharedUris` 分发前对每个 uri 做 `fileIo.statSync` 大小预检，
  超限直接返回 `TOO_LARGE`（对应原版 resolve 期拦截语义）。
- 通用 `ZIP_MAX_ARCHIVE_BYTES`（1GB）保留不动——`.note`/zip 归档
  导入与 PDF 打开在原版就是两条独立阈值路径。

### 3. 打开失败分类提示（vs8 映射）

- `LibraryPage.importSharedAndOpen`：`TOO_LARGE` →
  `open_pdf_too_large`（"This PDF is too large to import" /
  "PDF 过大，无法导入"）；其余非取消失败 → `open_pdf_failed`
  （"Couldn't open this PDF" / "无法打开此 PDF"）。
- 密码保护 PDF 保留现有 `pdfPasswordPrompt` 交互式输入（强于原版
  toast，登记为超集偏差）。

### 4. fail-closed 登记（ADR-0669）

- `update_*`（Play In-App Update）、`app_rating_*`（Play In-App
  Review）、`kbd_shortcut_*` 系统快捷键帮助组、
  `error_could_not_open_new_window`/`open_in_new_window`（多窗口）、
  `missing_native_library`（`.so` 加载失败）、动态快捷方式
  `shortcut_recent_note_long`/`shortcut_unfiled`/
  `shortcut_untitled_note`（`ShortcutManager` 动态注册）。
- `account_deletion_notice`/`force_logout`/`login_required_for_photo`/
  `note_limit_share` 随 ADR-0662 账号边界统一登记。

### 5. app_widgets__ 族收口

审计确认 20 键全部由 forms_config + FormFeed/Card/EditAbility +
ADR-0632/d05 系列覆盖；`*_login_required` 随账号边界登记。无新增
代码。

## 验证

- 新增 Replay：`docs/migration/replays/d02-original-app-tail.mjs`
  （33 断言全绿）。
- 全量 Desktop Replay：604/604 全绿。
- `note@default` / `note@ohosTest` 双 HAP 构建通过（clean 后复验）。

## 涉及文件

- `note/src/main/ets/data/NoteImporter.ets`
- `note/src/main/ets/ui/library/LibraryPage.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/adr/ADR-0669-original-app-tail.md`
- `docs/migration/evidence/original-app-tail-jadx-2026-09-25.md`
- `docs/migration/replays/d02-original-app-tail.mjs`
