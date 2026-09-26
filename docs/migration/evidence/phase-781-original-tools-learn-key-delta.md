# Phase 781 证据：原版 1.4.2 工具/学习键增量 + Phase 760 更正

日期：2026-09-29
性质：证据登记 + **更正 Phase 760 的 Learn 下线结论**
证据源：`decompiled_1.4.2` strings.xml；`decompiled_1.0.3`
strings.xml 对照；Harmony `StrokeTypes.ets`/`TapePatternPicker.ets`。
Replay：`docs/migration/replays/d02-original-tools-learn-key-delta.mjs`
ADR：`ADR-0725-original-tools-learn-key-delta.md`

## ⚠️ 更正：Learn AI 聊天并未下线

Phase 760 证据曾记 "feature_learn 键族 17→8，AI 聊天下线"。
前缀归一化（feature_learn__↔ui_learn__ 合并比对）后的真实结论：

- 聊天键**仍在**：`feature_learn__chat`/`chat_card_*`/`chat_send`
  幸存，`chat_error_*`/`chat_generating`/`chat_input_placeholder`
  等迁至 `ui_learn__*` 命名空间——这是**键名重组非功能下线**。
- 归一化后真正消失仅 4 键：`feature_learn_quiz__card_completed_score`
  （改键 learn_card_score）、`feature_learn_summary__{copy_all,
  more_options}`（改键 ui_learn__ 通用键）、
  `feature_learn_transcription__error_format`（唯一真删——
  转写错误格式键）。
- 新增聊天键：`chat_upsell_*`（订阅促销）+ quiz explain-chat 键。

## ui_tools__ 新键簇（34 键，除已登记的形状/钢笔族外）

- **胶带图案命名**：`tape_pattern_{checkers,dots,flowers,grid,
  hearts,plain,stars,stripes,waves}`——9 图案获得本地化名称。
  关键事实：Harmony `TapePattern` 枚举 0-8 与键序**逐一对应**
  （STRIPES/GRID/DOTS/PLAIN/STARS/FLOWERS/HEARTS/WAVES/CHECKERS），
  TapePatternPicker 已全量移植——1.4.2 只是给既有图案补名字。
- **笔刷包显示名**：`brush_pack_glitter`/`brush_pack_rainbow`
  （Phase 762 .brushpack 的 UI 名）。
- **工具箱细化**：`brush_width_option`/`color_hex`/`no_color`/
  `reset`/`google_ink_section_title`/`tool_with_effects`/
  `stroke_style_pill_description`/`stop_recording_elapsed`。

## 分类结论

- 胶带图案：Harmony 已对齐（枚举+选择器全在）；1.4.2 新增
  仅为名称串——**已移植面**，无回移动作。
- Learn 聊天存续更正写入 Phase 760 证据注记。
- 其余工具箱键：版本差登记。
