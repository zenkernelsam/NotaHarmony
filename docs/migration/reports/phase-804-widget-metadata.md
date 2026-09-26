# Phase 804 报告：桌面小部件元数据/尺寸映射收口

日期：2026-09-23
Phase 类型：证据登记（无代码改动）

## 摘要

对比原版 5 个 `app_widgets__*_info.xml` 与 Harmony `forms_config.json`
5 个 form，钉住小部件尺寸规格映射。widget-info 两版零 delta。

## 映射表

| 原版（targetCell） | Harmony form（default） | 差异 |
|--------------------|------------------------|------|
| create_note 2×2 | new_note_card 2*2 | 无 |
| create_recording 2×2 | new_recording_card 2*2 | 无 |
| note_thumbnail 2×2 | note_thumbnail_card 2*2 | 无 |
| recent_notes 4×2 | recent_notes_card 2*4 | Harmony 无 4*2 档 |
| folder_notes 4×2 | folder_notes_card 2*4 | Harmony 无 4*2 档 |

原版 `resizeMode=vertical|horizontal` ↔ Harmony `supportDimensions`
多档支持；`home_screen` ↔ 桌面卡片默认语义；preview 资源 ↔ form
displayName/description 本地化字符串。

## 验证

- `d02-widget-metadata.mjs`：6/6 green
- 全量 Desktop Replay 与双 HAP：见提交

## 产物

- 证据：`docs/migration/evidence/phase-804-widget-metadata.md`
- Replay：`docs/migration/replays/d02-widget-metadata.mjs`
- ADR：`docs/migration/adr/ADR-0748-widget-metadata.md`
