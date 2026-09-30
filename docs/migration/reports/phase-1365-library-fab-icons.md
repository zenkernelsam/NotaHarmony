# Phase 1365 — 库创建 FAB 速拨图标保真

## 摘要

原版 `cwi.b` chip 是 **图标+文字**（`go5.b` 图标 painter + `tpe.b` 标签），
Harmony 此前仅渲染文字。本阶段补齐图标：`CreateActionChip` 改为
`Row { Image(icon) + Text }`，并按 `cd` case 0 每项的原版 drawable
（`feature_library__importnewnote`/`templatenewnote`/`createnote`、
`ui_fileimport__docscan`）逐字节移植为 `fab_*` SVG，含暗色限定符变体
（`dark/media`，stroke→`#E6E6E6`）。Record chip（ADR-0655 等价项）用现成
`shortcut_new_recording`。

## 改动

- `note/.../LibraryPage.ets`：`CreateActionChip` 加 `icon` 形参 + `Image`。
- `note/.../resources/base/media/fab_{import,templates,docscan,createnote}.svg`（新增）。
- `note/.../resources/dark/media/fab_*.svg`（暗色变体，新增）。
- `docs/migration/replays/d02-library-fab-order.mjs`：24/24。
