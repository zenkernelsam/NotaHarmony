# Phase 690 — 原版文字颜色（qte → zyd.g foregroundColor）移植

## 范围

原版文字色井/色板（`hue`→`qse.O` 面板、`qte`/`ste` → `zyd.g` iu1 负载）
补进 `TextBlockOverlay`：`foregroundColor` 字符 run 的写入、选区应用、
折叠光标预期属性与 Automatic 缺省恢复。渲染端
（`style.foregroundColor ?? element.fontColor`）此前已就位。

## 原版行为（证据见 phase-690 evidence）

- `cve` `qte` 分支：选色 → 更新色井态 `this.Y` + `zyd{...,iu1(j),...}`
  mask1983 写前景色字段。
- `cve` `ste` 分支：`e.f(ste.a)` 直接写选区文字色，`i(qse.S)` 收面板。
- `cve` `hue` 分支：打开 `qse.O` 文字色面板（`i31` 字体面板色井区）。
- `zyd.g`=`iu1` 前景色；字段缺省=`element.fontColor`。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `TEXT_COLOR_PRESETS`：与 `ColorPickerView.presetColors` 同源 12 色
    ARGB 预设（黑/灰/红/橙/黄/绿/青/蓝/紫/粉/棕/白）。
  - `applyForegroundColor(color|null)`：区间三切分写 `foregroundColor`；
    `null`→`undefined`（JSON 规范归并剔空样式），非 null 对空白段
    gap-fill。
  - `pickTextColor(color)`：选区写 run；折叠光标写
    `pendingCharStyles.foregroundColor`。
  - `clearTextColor()`（Automatic）：选区 `applyForegroundColor(null)`；
    折叠光标 `pendingClearForeground`。
  - `buildTextColorSheet()`：4 列 12 色圆点网格 + Automatic 按钮的
    `bindSheet`（`SheetSize.MEDIUM`）；选色/清除后自闭合。
  - `Color` 按钮置 Highlight 之后、列表装饰之前（颜色簇末位）。
- 新增字符串 ×2（en/zh）：`text_color`="Color"/"颜色"、
  `color_automatic`="Automatic"/"自动"。

## 验证

- Replay：`d02-original-text-color.mjs` 16 项全绿；lease-bound
  enabled 计数 19→22（色板圆点 + Automatic + 行钮三处新增）。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）。

## 限制

- 色井"当前色一键应用"手势未实现（sheet 一步选色，无语义损失，
  记 evidence 受限等价）。
- 沿用 ADR-0648/0650 登记差异（CRDT 写侧无本地 style-op 编码器等）。
- 字体族（`nte`/`zq8`）、链接（`tte`/`aue`/`mte`）仍属后续 Phase。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/replays/d02-original-text-color.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
