# Phase 1424 证据：ui_tools__* 残留扫描与笔刷效果选择器 fail-closed

## 扫描范围

原版 1.4.2 `ui_tools__*` 共约 79 键。逐一对照 Harmony 现状：

| 原版键 | 原版用途 | Harmony 状态 |
|--------|----------|--------------|
| `brush_style_fixed/variable/dashed/dotted` | 笔刷样式项（u4h，yxi.java:79-82） | 已移植 MONO/TAPER/DASH/DOT（EditorToolbar 553-556） |
| `brush_pack_rainbow` / `brush_pack_glitter` | 效果 chip 标签（t4h，yxi.java:89/93） | **fail-closed，本期裁决** |
| `tool_with_effects` | "tool with effects %s, %s" a11y（cti.java:672） | 随效果 picker fail-closed |
| `stroke_style_pill_description` | 样式+效果合并描述 a11y（u81.java:319） | 样式部分已由 StyleButton a11y 覆盖；效果部分随 picker fail-closed |
| `google_ink_section_title` | 效果区段标题（yxi.java:95） | fail-closed |
| `eyedropper` / `stabilization` / `width` / `color_hex` | 取色器/防抖/宽度/色值 a11y | 均已移植 |
| `laser` / `ruler` / `zoom` | 激光/尺子/缩放工具 | 已移植或已裁决 |
| `color_options` | 色板选项 chevron（e6n.java:474） | 已由长按色井编辑 affordance 覆盖（ColorPicker.ets:107） |

## 效果 picker 的证据链

`yxi.java:69-99`（笔刷设置行构建器）：

```
wsiVar instanceof qj4 && ((!(wsiVar instanceof wri) || i35.c flag) && zm7.K non-empty)
  → z = ∃ zm7∈K : i35.a(zm7)          // 任一效果远端开关开
if (z) → 追加 y4h(google_ink_section_title, [t4h(RAINBOW)…, t4h(GLITTER)…])
```

- `t4h` chip 仅在 `i35.a(zm7)` 为真时出现——`i35.java` 中该函数读 `vnh`
  DataStore/远端 flag（ordinal 0→a，1→b），另有 `i35.c` 门控 `wri` 变体。
  即：**原版中该区段也是远端特性开关门控的 Google Ink 专属 UI**，非常驻。
- chip 标签资源名为 `brush_pack_*`，区段标题为 `google_ink_section_title`——
  效果即 Google Ink 笔刷包效果。
- 选择回写：`c71` 映射选择→效果对象，`urm` 序列化为 bitmask，`jz0.j` 聚合
  出 RAINBOW/GLITTER/RAINBOW_GLITTER 组合枚举（`b71`）。
- a11y：`cti.java:672` 用 `tool_with_effects` 播报 "工具 + 效果名"；
  `u81.java:319` 用 `stroke_style_pill_description` 拼接样式+效果列表。
  两者均仅在效果存在时生效。

## 渲染依赖

- `assets/brushpacks/rainbow.brushpack` 等为 ZIP+gzip `brush_family.proto`——
  Google Ink 专有笔刷族资产（d02-original-brushpack-format.mjs 已钉住格式）。
- `k06.java` 定义 RAINBOW=1/GLITTER=2 线格式 bitmask；`s06`/`l06` 物化
  bitmask+tinted+phaseOffsetPx。
- **Java 层无 RAINBOW/GLITTER shader**：最终着色委托 WetMirror/native
  笔刷引擎。ADR-0046 已明确："Inventing a Harmony gradient or particle
  shader would not be an evidence-based port."
- `ToolStateEntity.googleInkBrushPackId` 已按 ADR-1327 裁决恒 NULL（B 类
  专有 SDK fail-closed），仅保留列供 schema 校验/导入往返。

## 结论

picker + a11y + 区段标题三者均是 flag-gated Google Ink 表面，渲染依赖专有
native 引擎与打包资产。Harmony 继续按 ADR-0046 做数据无损透传
（`inkEffects`/`inkEffectsTinted`/`inkEffectPhase`），不做效果选择 UI，
不做近似 shader——本阶段仅补 picker 侧裁决文书，代码零改动。
