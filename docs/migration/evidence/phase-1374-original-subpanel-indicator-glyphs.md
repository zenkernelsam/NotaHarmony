# Phase 1374 证据 — 子面板/拖拽柄/剩余指示标记矢量化

- 日期：2026-08-09
- 范围：分享子面板、缩放视图、设置/导入单、调色板与桌面卡片的剩余
  Unicode/Emoji 指示占位迁到原版矢量。
- Replay：`docs/migration/replays/d02-original-subpanel-indicator-glyphs.mjs`
  （16/16）

## 提取结果

- `_gen_toolglyphs.cjs` 新增 `drag_handle`（o 槽，`M2,8H22 M2,12H22
  M2,16H22`，`sw:1.25`）。`ToolGlyphs.ets` 现 39 键。
- 新增 `note/src/main/resources/base/media/edit.svg`，逐字节复刻
  `ui_designsystem__edit` 的 2 条 stroke pathData（`stroke-width 1.25`、
  `stroke-linecap/linejoin round`）。

## 原版证据

- `wfg.c`：缩放视图控制条 `drag_handle` + "Move Zoom View"，`qeg` 上下两档
  停靠。`ui_designsystem__drag_handle.xml` 为 3 条水平描边线。
- `ue4`：分享子面板的前进/返回箭头为 `chevron_right`/`chevron_left`。
- `te4`：导入单重排为 Compose 可拖拽行（`pd8`/`md8.I`），
  `ui_fileimport__move_up`/`move_down` 仅作无障碍动作；无可见箭头图标。
  Harmony 的显式上下按钮为迁移适配，映射 `chevron_down`(上移 rot180)。
- 设置/导入单选中勾：`general_check_med_reg`（与 Phase 1373 文件夹选中
  同一选中指示语义）。
- widget 编辑角标：`ui_designsystem__edit`（铅笔描边矢量）。

## widget 受限说明

`noteformability/pages/*Card.ets` 运行在 FormExtensionAbility 卡片渲染
管线，组件白名单不含 `Shape`/`Path`，也不能宿主普通 `@Component`。
因此 `ToolGlyph` 不可用于卡片；改用 `Image($r('app.media.edit'))` +
`.fillColor()` 渲染同名矢量。此为 fail-closed 适配：原意图形得到保留，
仅渲染通道不同。

## 保留未迁移项（刻意）

- 缩放 `+`/`-`（`TextBlockOverlay`、`NoteCanvasView`）：Harmony 适配控件，
  无直接原版等价（原版缩放视图用 back/forward/return/close），ADR-1308 已记。
- `LibraryPage` emoji 网格 `∅`：贴纸选择器的「无」格，为文本语义符号，
  非矢量图标。
