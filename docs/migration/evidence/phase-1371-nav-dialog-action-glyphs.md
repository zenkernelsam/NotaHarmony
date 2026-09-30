# Phase 1371 — 导航 / 对话框 / 溢出按钮改用原版矢量图标

## 原版证据（decompiled_1.0.3）

`ue4.java` 是导航/对话框图标提供者：
- `ue4.r()` → `ui_designsystem__back_arrow`（返回）
- `ue4.t()` → `ui_designsystem__chevron_right`
- `ue4.u()` → `ui_designsystem__close_med_regular`（关闭）
- `ue4.x()` → `ui_designsystem__more`（三点溢出）
- `d32.java` → `ui_designsystem__chevron_left`（上一条/返回）
- `ke1.java`/`d32.java` → `ui_designsystem__hamburger`、`more`（go5.b 单色调）

填充/描边判定（`resources/res/drawable/`）：
- `more`：`fillColor=#444f60` 三实心点 → `f` 槽。
- `back_arrow`/`chevron_*`/`close_med_*`：`fillColor=#00000000` + `strokeColor`
  → 描边矢量 → `o` 槽（`contentColor` 描边）。

## Harmony 实现

`_gen_toolglyphs.cjs` 的 `T` 追加 7 个导航/对话框键；`ToolGlyphs.ets`
现 25 键。以下占位 `Button('…')` 全部换成 `Button(){ ToolGlyph(...) }`：

| 文件 | 占位 → 字形 |
|------|-------------|
| ToolboxSettingsDialog | `✕`→`close_med_regular`、`▲`→`chevron_down`(rot180)、`▼`→`chevron_down`、`⋯`→`more` |
| PageOverviewPanel | `✕`→`close_med_regular` |
| PageManagerBar | `...`→`more` |
| NotePage | `...`→`more` |
| TapePatternPicker | `‹`→`chevron_left` |
| PageSettingsPanel | `⋯`→`more` |
| SettingsPage / WebDAV / RecentlyDeleted / DefaultTemplate / BackupPage | `<`→`back_arrow` |
| LibraryPage | `...`×3→`more`、`☰`→`hamburger` |

全部保留 onClick / enabled / opacity / bindMenu / bindPopup / a11y。

## 已知近似

`▲`/`▼` 为拖拽重排（`drag_handle`）的按钮等价近似；`▲`= `chevron_down`
旋转 180°（无 `chevron_up` 资源）。见 ADR-1307。

## 验证

- `d02-original-nav-action-glyphs.mjs`：46/46。
- 全量 Replay：1224/1224。
- `note@default` / `note@ohosTest` clean 构建成功。
