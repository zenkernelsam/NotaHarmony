# Phase 698 — 原版文字色/高亮面板 HSV 取色器（rw1/t8j/hv1/ru1）移植

## 范围

原版文字前景色与高亮色彩面板内嵌的 HSV 自定义取色器
（`mli.c`→`rw1.c` 面板、`t8j` 拖拽取色区、`ru1` HSV 状态）——
此前 Harmony 仅提供预设色板。

## 原版行为（证据见 phase-698 evidence）

- 前景色面板（`hse` case 2）与高亮面板（case 1）同构，均含
  HSV 取色子面板 + 预设网格 + 最近色 + eyedropper/remove。
- 取色器 = SV 方盘 + 色相条，拖拽更新 `ru1(h,s,v)`，确认后应用。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `hsvH/hsvS/hsvV` @State + `hsvTarget`（0=前景 1=高亮）。
  - `hsvComponentsToArgb`（te5.B 等价）、`seedHsvFromArgb`
    （Color.RGBToHSV 等价）、`hsvSeedColor`（按 target 取当前色
    种子：前景=选区 run/元素字色，高亮=首个 highlight run/默认黄）。
  - `buildHsvSheet`：预览+H/S/V 读数、SV 方盘（色相底+白→透明
    横向渐变+透明→黑纵向渐变+拇指，`onTouch` 坐标比例→sat/val）、
    色相条（6 停点彩虹渐变+拇指，x→hue）、Apply/Cancel。
  - 入口：文字色 sheet 加 "Custom…" 按钮；高亮菜单加 "Custom…"
    项；共享 `showHsvSheet` bindSheet。
  - `confirmHsvColor` 按 target 分派 `pickTextColor`/
    `toggleHighlightColor`（复用 P688/P690 管线）。

## 验证

- Replay：`d02-original-text-hsv-picker.mjs` 27 项全绿；
  lease-bound 计数 29→33（SV 方盘/色相条/Apply/Custom 四处
  lease 门控）。
- 构建：`note@ohosTest`/`note@default` assembleHap 成功。
- 真机/模拟器：未验证（约束内）。

## 限制

- 最近色行（`zw1`）与 eyedropper 面板内入口未纳入——eyedropper
  画布管线已存在（ADR-0646），文本面板复用需额外接线，登记差异。
- SV 方盘为双层渐变近似（色相底+白/黑渐变），与原版的
  Compose 渐变停点布局在视觉边缘上可能有细微差别；拖拽语义一致。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/replays/d02-original-text-hsv-picker.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
