# Phase 1424：ui_tools__* 残留扫描 — 笔刷效果选择器 fail-closed 报告

- 日期：2026-10-01
- 状态：完成（裁决阶段，代码零改动；Desktop Replay 10 项本 Phase 检查）
- 证据：`docs/migration/evidence/phase-1424-brush-effects-picker.md`
- 决策：`docs/migration/adr/ADR-1360-brush-effects-picker-failclosed.md`
- Replay：`docs/migration/replays/d02-original-brush-effects-picker.mjs`

## 目标

扫描原版 `ui_tools__*` 资源族（约 79 键）残留，重点裁决 Rainbow/Glitter
笔刷效果 chip（`ui_tools__brush_pack_*`）是否为可移植缺口。

## 裁决结果：fail-closed（文档化，非实现）

原版效果 picker 是**远端开关门控的 Google Ink 专属表面**，三重证据：

1. **UI 层**：`yxi.java:69-99` 中 `t4h` 效果 chip 挂在
   `google_ink_section_title` 区段下，逐个由 `i35.a(zm7)` 的 `vnh`
   DataStore/远端 flag 门控；原版默认也不显示。
2. **资产层**：效果本体是 `assets/brushpacks/*.brushpack` 打包专有资产
   （ZIP+gzip `brush_family.proto` = Google Ink 笔刷族），Harmony 无
   本地对应物；`googleInkBrushPackId` 已按 ADR-1327 裁决恒 NULL。
3. **渲染层**：`k06` 位掩码仅作数据；Java 层无 shader，着色委托
   WetMirror/native 引擎（ADR-0046 已裁决"发明近似 shader 非证据移植"）。

只加 picker 而无真实着色会让笔画元数据与外观系统性背离，故连 UI 也不做。
`inkEffects`/`inkEffectsTinted`/`inkEffectPhase` 继续按 ADR-0046 在持久化、
擦除、剪贴板、形状转换中无损透传。

## 同族其他键处置

- `brush_style_*` 4 项、`eyedropper`、`stabilization`、`width`、
  `color_hex`、`laser`、`zoom`：已移植覆盖。
- `tool_with_effects`、`stroke_style_pill_description`（效果部分）、
  `google_ink_section_title`：随 picker fail-closed。
- `color_options`：原版色板 chevron，已由长按色井编辑 affordance 覆盖。
- `ruler`：`s01.a0` 原版即隐藏，ADR-0644 已裁决。

## 验证

- `d02-original-brush-effects-picker.mjs`：10/10 通过，钉住
  （a）数据字段与位掩码注释保留；（b）ToolState 无效果列、
  googleInkBrushPackId 恒 NULL；（c）无 picker 字符串/UI/setter；
  （d）渲染器不消费 inkEffects。
- 全量基线与双构建结果见提交说明。
