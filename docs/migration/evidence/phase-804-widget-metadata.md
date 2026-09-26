# Phase 804 证据：桌面小部件元数据/尺寸映射收口

日期：2026-09-23
输入：`decompiled_{1.0.3,1.4.2}/resources/res/xml/app_widgets__*_info.xml`、
`note/src/main/resources/base/profile/forms_config.json`、
`note/src/main/module.json5`

## 1. 版本间 delta

5 个 `app_widgets__*_info.xml` 文件名与内容在 1.0.3 ↔ 1.4.2 **完全一致**
（basename diff 为空）。小部件面零版本增量。

## 2. 原版小部件规格（5 个）

| Widget | minW×minH | targetCell | resizeMode | 分类 |
|--------|-----------|-----------|------------|------|
| create_note | 40×40dp | 2×2 | 双向可调 | home_screen |
| create_recording | 40×40dp | 2×2 | 双向可调 | home_screen |
| note_thumbnail | 40×40dp | 2×2 | 双向可调 | home_screen |
| recent_notes | 250×110dp | **4×2** | 双向可调 | home_screen |
| folder_notes | 250×110dp | **4×2** | 双向可调 | home_screen |

全部 `widgetCategory=home_screen`、带 previewLayout/previewImage。
另有 `WidgetImageProvider`（图片渲染 provider）+ `Widget*` receiver
已在 Phase 800 登记。

## 3. Harmony 映射（`forms_config.json` 5 个 form）

| Harmony form | default | supportDimensions | 对应原版 |
|--------------|---------|-------------------|----------|
| new_note_card | 2*2 | [2*2] | create_note (2×2) |
| new_recording_card | 2*2 | [2*2] | create_recording (2×2) |
| note_thumbnail_card | 2*2 | [1*2, 2*2, 2*4, 4*4] | note_thumbnail (2×2) |
| recent_notes_card | 2*4 | [2*2, 2*4, 4*4] | recent_notes (**4×2**) |
| folder_notes_card | 2*4 | [2*2, 2*4, 4*4] | folder_notes (**4×2**) |

### 尺寸语义差异（平台约束，登记不改码）

- Android `targetCellWidth/Height` 为桌面格数；原版列表型小部件以
  **4 宽 × 2 高** 为推荐尺寸。
- Harmony `formDimension` 枚举仅支持 `1*2 / 2*2 / 2*4 / 4*4`——
  **不存在 4 宽×2 高**。Harmony 采用 `2*4` 默认 + 多档支持，是
  平台可用选项内最接近等价的选择。
- 单一方块类（create_note/create_recording/note_thumbnail）2×2
  精确对齐，无差异。
- 原版 `resizeMode=vertical|horizontal` ↔ Harmony
  `supportDimensions` 多档——语义等价（可调/多档）。
- `widgetCategory=home_screen` ↔ Harmony form 默认即桌面卡片；
  `previewImage/previewLayout` ↔ form 的 `$string:form_*_display/desc`
  （Harmony form picker 以名称+描述呈现）。

## 4. 结论

小部件元数据面收口：5→5 功能映射完整（Phase 800 已证 Ability/卡页面
对应），本 Phase 钉住尺寸规格：3 个 2×2 精确对齐，2 个列表型由
4×2 调整为 2*4（Harmony 无 4*2 档），属平台网格约束差异。
