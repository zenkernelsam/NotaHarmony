# ADR-1360：笔刷效果（Rainbow/Glitter）选择器 fail-closed

## 状态
Accepted — Phase 1424（补充 ADR-0046 数据层裁决的 picker 侧）

## 背景
ADR-0046 已将 `inkEffects` 位掩码（RAINBOW=1/GLITTER=2）裁决为**数据无损
透传**：CRDT/持久化/剪贴板/撤销快照全链保留，但明确不声称视觉等价——
Java 层无 shader，原版着色委托 WetMirror/native 引擎。ADR-1327 将
`ToolStateEntity.googleInkBrushPackId` 裁决为恒 NULL（Google Ink 专有
SDK fail-closed）。

Phase 1424 扫描 `ui_tools__*` 残留后需裁决剩余的**选择器侧**：原版笔刷
设置行（`yxi.java:69-99`）在样式项之外是否还有一个可移植的效果选择区段。

## 证据
- 原版效果 chip（`t4h`）在 `ui_tools__google_ink_section_title` 区段标题
  下渲染，且每个 chip 由 `i35.a(zm7)` 的 `vnh` 远端特性开关单独门控，
  区段整体还要求 `wsiVar instanceof qj4`（Google Ink 工具态）。
  **即便在原版中这也是远端开关门控的非默认表面。**
- 效果本体来自打包的专有资产：`assets/brushpacks/rainbow.brushpack` 为
  ZIP+gzip `brush_family.proto`（Google Ink 笔刷族描述），无法本地复现。
- a11y 键 `tool_with_effects`/`stroke_style_pill_description` 仅在效果
  存在时生效；样式部分已由现有 StyleButton a11y 覆盖。
- 若只加 picker 加 bitmask 而无真实着色，笔画外观将与其元数据系统性
  背离（带效果位却渲染为普通色）——比缺 picker 更差。

## 决策
1. 不实现 Rainbow/Glitter 效果 chip、Google Ink 区段标题及相关 a11y
   播报；`ToolState` 不增设效果字段。
2. 维持 ADR-0046 数据契约：`inkEffects`/`inkEffectsTinted`/`inkEffectPhase`
   经持久化、擦除、剪贴板、形状转换无损透传，供未来真实引擎接管。
3. 渲染器不消费 `inkEffects`：近似渐变/粒子 shader 属发明行为而非
   证据移植，拒绝。
4. 若未来出现可复现的本地笔刷引擎，本 ADR 随 ADR-0046 的 "Remaining
   boundary" 一并复审。

## 验证
- 新 fixture `d02-original-brush-effects-picker.mjs`（10 检）钉住契约：
  数据字段保留、位掩码注释在位、ToolState 无效果列、无 picker 字符串/
  UI/setter、渲染器不消费 inkEffects。
- 全量 Desktop Replay 基线见阶段报告。
