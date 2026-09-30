# Phase 1373 证据 — 状态/指示标记原版矢量字形

- 日期：2026-08-09
- 范围：库卡片/页/多选界面上的状态与指示标记从 Unicode/Emoji 占位迁到
  `ui_designsystem__*` 矢量字形。
- Replay：`docs/migration/replays/d02-original-status-indicator-glyphs.mjs`
  （28/28）

## 原版 drawable 提取结果

`_gen_toolglyphs.cjs` 从
`decompiled_1.0.3/resources/res/drawable/` 提取并写入
`note/src/main/ets/ui/components/ToolGlyphs.ets`（共 38 个键）。
本 Phase 新增 8 个指示字形：

- `favorite_fill`（f 槽，填充）
- `record_mic_outline`（o 槽，描边）
- `record_mic_fill`（f 槽，备用）
- `general_check_med_reg`（o 槽）
- `check_tiny_bold`（o 槽）
- `edit`（o 槽）
- `checkmark_circle`（f 槽，选中实心圈带勾）
- `circle_empty_med_outline`（o 槽，空心描边圈）

`bookmark_tall_fill`/`more`/`chevron_left`/`chevron_right` 在前序 Phase 已入库。

## 原版调用证据

- `o94`（多选勾选圈）：已选 `checkmark_circle`（填充），未选
  `circle_empty_med_outline`（描边圈）。库/页/工具条三处选择态圆点已统一。
- `md.java`：页缩略图书签角标 `bookmark_tall_fill`/`bookmark_tall_outline`
  （当前已书签态用 fill）。
- `w09.l`：笔记卡录音角标 `record_mic_outline`（注释中明确标识）。
- `b41`/`o94`：文件夹行选中指示 `general_check_med_reg`。
- `b5j`/`m5j`：单元格溢出按钮 `ui_designsystem__more`。
- `ue4`：页前后导航 `chevron_left`/`chevron_right`（`ue4` 图标提供者）。

## Harmony 实现

- 复用 `ToolGlyph` 单层渲染；指示字形走 `f`/`o` 槽，经 `contentColor`
  着色。
- `ToolGlyph.contentColor` 类型放宽为 `ResourceColor`，支持
  `Color.White` 未选态描边圈。
- `NavigationButton(label, previous)` 签名收窄为
  `NavigationButton(previous)`，按方向选 `chevron_left/right`。

## 差异说明

- 未选态圆圈的底色/描边宽度按 ArkUI `ToolGlyph` 单层渲染（`o` 槽描边），
  不再叠加 `backgroundColor`/`borderRadius` 文本圈；视觉等价为原版
  `circle_empty_med_outline` 矢量。
- `record_mic_fill` 已提取备用；当前两处录音角标按 `w09.l` 证据采用
  outline 变体。
