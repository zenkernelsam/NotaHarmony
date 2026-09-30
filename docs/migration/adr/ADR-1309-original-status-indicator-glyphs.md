# ADR-1309 — 状态/指示标记改用原版 ui_designsystem__* 矢量图标

- Phase：1373
- 状态：Accepted
- 日期：2026-08-09
- 关联：ADR-1305（五层 m4f 工具字形渲染）/ ADR-1306（工具条动作字形）/
  ADR-1307（导航/对话框字形）/ ADR-1308（页/区块控制字形 + 每字形原生
  viewport）

## 背景

工具条动作、导航/对话框、页/区块控制按钮在此前三个 Phase 已迁到原版
矢量字形。本 Phase 收敛到库卡片与页/多选界面上的「状态/指示标记」——
这些此前用 Unicode/Emoji 占位（`✓`、`♥`、`🎙`、`🔖`、`⋯`、`<`/`>`）。

原版证据（decompiled_1.0.3 `resources/res/drawable` + 调用类）：

| 界面 | 占位 | 原版 drawable | 调用/证据 |
|------|------|---------------|-----------|
| 笔记卡收藏角标 | `♥` | `ui_designsystem__favorite_fill` | 卡片 favorited 覆盖层 |
| 笔记卡录音角标 | `🎙` | `ui_designsystem__record_mic_outline` | `w09.l` |
| 多选勾选圈(已选) | `✓` 实心 | `ui_designsystem__checkmark_circle` | `o94` |
| 多选勾选圈(未选) | `✓` 空圈 | `ui_designsystem__circle_empty_med_outline` | `o94` |
| 文件夹/分区选中 | `✓` | `ui_designsystem__general_check_med_reg` | `b41`/`o94` |
| 页书签角标 | `🔖` | `ui_designsystem__bookmark_tall_fill` | `md.java` |
| 单元格溢出菜单 | `⋯` | `ui_designsystem__more` | `b5j`/`m5j` |
| 页前后导航 | `<`/`>` | `ui_designsystem__chevron_left`/`chevron_right` | `ue4` |

## 决策

复用 `ToolGlyph` 单层渲染路径渲染这 8 个新字形（全部落在 `f`/`o` 槽，
无 highlight/shadow/overlay），`contentColor` 由主题 token 驱动。同时
把 `contentColor` 的 prop 类型从 `string` 放宽为 `ResourceColor`，以便
覆盖未选态的白描边圈（`Color.White`）等非字符串颜色。

`PageManagerBar.NavigationButton` 原先以 `label` 字符串渲染 `<`/`>`，
改为按 `previous` 标志直接选择 `chevron_left`/`chevron_right`，签名同步
收窄（删除无用的 `label` 形参）。

## 替换明细

- `LibraryPage`：`♥`×2 → `favorite_fill`；`🎙`×2 → `record_mic_outline`；
  `✓`（文件夹/分区选中）×2 → `general_check_med_reg`；`SelectCircle`
  `✓`/空圈 → `checkmark_circle`/`circle_empty_med_outline`；`⋯`
  `NoteMenuButton` → `more`。
- `PageOverviewPanel`：`🔖` 角标 → `bookmark_tall_fill`；选择态 `✓`/空圈 →
  `checkmark_circle`/`circle_empty_med_outline`。
- `EditorToolbar`：内容管理选择态 `✓`/空圈 → `checkmark_circle`/
  `circle_empty_med_outline`。
- `PageManagerBar`：`🔖` 指示 → `bookmark_tall_fill`；`<`/`>` 翻页 →
  `chevron_left`/`chevron_right`。

所有被替换元素的无障碍文本保持原值（`folder_selected`、`select_note`、
`note_actions`、`bookmark_page`、`previous_page`/`next_page`），仅更换
视觉渲染。

## 兼容性与回退

- `ToolGlyph` 的 `contentColor: ResourceColor` 是向后兼容的放宽
  （既有 `string` 调用仍合法）。
- 字形数据由 `_gen_toolglyphs.cjs` 从原版 drawable XML 逐字节提取，
  pathData 已比对一致。

## 验证

- `d02-original-status-indicator-glyphs.mjs`：28/28。
- 更新既有 fixture 锚点（folder-dialog-labels / library-favorites /
  library-multi-select / nav-action-glyphs / page-bookmark-parity /
  page-bar-shared-lease-bound / editor-toolbar-glyphs 计数 30→38）。
- 全量 Desktop Replay 基线全绿。
- `note@default` 与 `note@ohosTest` 静态构建成功。
