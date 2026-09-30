# Phase 1369 — 工具条字形补齐 m4f 五层（highlight/shadow/overlay）

## 原版证据（`ho5` 注册表 + `tn8`/`gt` 渲染序）

`ho5.java` 每工具注册完整 `m4f`：
`new m4f(X_outline, X_highlight, X_shadow, X_overlay, X_fill)` ——
`a=outline, b=highlight, c=shadow, d=overlay, e=fill`（b/c/d 为可空 Integer）。

`tn8` 使能分支（`zBooleanValue=true`，工具条常态）逐层 `go5.b`：

| 序 | 字段 | 层 | 渲染（go5.b 第4参为 ColorFilter tint） |
|----|------|----|--------------------------------------|
| 1 | `e` | fill | `wrdVar.getValue()` 状态/笔刷色（`cq.h` 下为 brushColor） |
| 2 | `d` | overlay | `iu1.b(dark?0.35:0.75, b.a)` 亮调 |
| 3 | `b` | highlight | `iu1.b(dark?0.5:c.a… / 0.65:b.a)` 亮调（`gt` case4） |
| 4 | `c` | shadow | `iu1.b(dark?0.4 / 0.25, …)` 暗调（`gt` case4） |
| 5 | `a` | outline | `wrdVar` 状态色描边（含二次 a11y 描边） |

各层 pathData 在 `res/drawable/ui_designsystem__<tool>_{highlight,shadow,overlay}.xml`，
fillColor 基底 `#ffffff`（overlay/highlight）/`#000000`（shadow）——即原版亮/暗
主题令牌。`x90.b(boolValueOf)` 为状态门，工具条使能态恒真 → 五层恒渲染。

## 修正

- `ToolGlyphs.ets` 扩为六字段 `{f,o,sw,h,s,v}`：9 个合成工具全部补齐
  highlight/shadow/overlay pathData（逐字节）；`eraser_partial`/`eraser_whole`
  单图标仍仅其一层。
- `ToolGlyph` 渲染五层：fill→overlay→highlight→shadow→outline，新增 `dark`
  prop 驱动 tn8/gt 的明/暗透明度分叉（亮层 #ffffff、暗层 #000000 近似主题令牌）。
- `EditorToolbar` 新增 `isDark()`（themeMode/systemDark），三处 ToolGlyph 传 `dark`。

## 验证

`d02-original-editor-toolbar-glyphs.mjs` 扩至 **91/91**：五层 pathData 存在性、
tn8 叠层序、各层 fillOpacity 明/暗值、`dark` prop 接线。`note@default` 构建绿。
