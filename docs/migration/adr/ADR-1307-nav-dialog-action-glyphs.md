# ADR-1307: 导航 / 对话框 / 溢出按钮改用原版 ui_designsystem__ 图标

- 状态：已采纳
- 阶段：Phase 1371
- 关联：ADR-1305/1306（tool 与 toolbar 动作字形）、`ToolGlyph.ets`、
  `ToolGlyphs.ets`

## 背景

Phase 1368–1370 把编辑器工具条全部矢量化。其余 UI 仍残留一批
**Unicode 占位**图标按钮：

| 占位 | 位置 | 原版资源（证据类）|
|------|------|-------------------|
| `<` | SettingsPage / WebDAV / RecentlyDeleted / DefaultTemplate / BackupPage 返回 | `ui_designsystem__back_arrow`（ue4.r）|
| `‹` | TapePatternPicker 返回 | `ui_designsystem__chevron_left`（d32）|
| `✕` | ToolboxSettingsDialog / PageOverviewPanel 关闭 | `ui_designsystem__close_med_regular`（ue4.u）|
| `⋯`/`...`/`☰` | 工具箱工具溢出、页管理溢出、NotePage 选项、模板间距溢出、库文件夹/库操作溢出、compact 文件夹抽屉 | `ui_designsystem__more`（ue4.x）/ `hamburger` |
| `▲`/`▼` | ToolboxSettingsDialog 上移/下移 | `ui_designsystem__chevron_down`（▲ 旋转 180°）|

## 决策

全部复用 `Shape + Path + viewPort(24)` `ToolGlyph` 管线：

- **平面单色调**（`back_arrow`/`chevron_*`/`close_med_*`/`hamburger`）——
  `go5.b` ColorFilter 整体 tint，进 `o` 槽以 `contentColor` 描边。
- **`more`**——三个实心圆点，进 `f` 槽以 `contentColor` 填充。
- 这些图标只有单层，`dark` prop（控制 h/s/v 明暗分层透明度）对它们无影响，
  故未接线（PageSettingsPanel 的间距按钮随 accent 选中态传了 `dark`）。

## 已知近似（fail-traceable）

`▲`/`▼` 移动工具是 **Harmony 等价控件**：原版工具箱设置用
`ui_designsystem__drag_handle` 拖拽重排，Harmony 对话框以按钮近似。
无 `chevron_up` 资源，`▲` 以 `chevron_down` + `.rotate(180°)` 表达。

## 验收

- `d02-original-nav-action-glyphs.mjs`：46/46。
- 全量 Replay 基线：1224/1224。
- `note@default` / `note@ohosTest` clean 构建成功。
