# Phase 698 — 原版文字色/高亮面板 HSV 取色器（rw1/t8j/hv1/ru1）Evidence

## 范围

原版文字前景色（`qse.O`/`qte`）与高亮色（`qse.R`/`rte`）色彩面板
共用的 HSV 自定义取色器；Harmony 此前仅有预设色板。

## 原版证据（decompiled_1.0.3）

### 1. 面板结构 `mli.c` → `rw1.c`

`mli.java`：

```java
a2dVar.add(zw1.a);                        // RecentColors 区
if (function4 != null) a2dVar.add(new ax1(function4));  // RemoveHighlight
a2dVar.add(new xw1(ix4Var2, ra, function0));            // EyeDropper
rw1.c(a2dVarN, ix4Var, new ru1(h,s,v), false, ...);     // HSV 种子=当前色
```

`hse.java` case 1/2：高亮面板（`tseVar.k`）与前景色面板
（`tseVar.i`）都走 `mli.c` —— 两个面板同构。

### 2. `rw1` 面板内容

- `ui_tools__colors` 标题 + 预设色网格（`j33.a`，8/行）。
- `ui_tools__recent_colors` 最近色行（7 槽）。
- `rw1.g("ColorPicker", o22)` 命名的 HSV 取色子面板。
- `rw1.h`：选色即应用（`ix4Var.invoke(new iu1(j))`）。

### 3. `t8j`/`hv1`/`ru1` —— HSV 取色器

- `ru1` = `ColorHSV(hue, sat, colorValue)`，`a()` = `te5.B(h,s,v)` →
  颜色 long。
- `hv1` 取色器体：三个拖拽回调各自把 (h,s,v) 新分量写回 `ru1`。
- `t8j` 取色区：`q8e.a(pd8, PointerInputEventHandler)` 两处
  pointer-input 拖拽分区（SV 方盘 + 色相条），`k1a` 渐变停点。

## Harmony 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `ru1(h,s,v)` 状态 | `@State hsvH/hsvS/hsvV` |
| `te5.B`/`ru1.a()` HSV→色 | `hsvComponentsToArgb(h,s,v)` 纯函数 |
| `Color.RGBToHSV` 种子 | `seedHsvFromArgb(argb)` |
| `mli.c` 以当前色开面板 | `openHsvSheet(target)` → `hsvSeedColor()`（fg=选区 foregroundColor run 否则元素字色；hl=首个 highlightColor run 否则默认黄） |
| `t8j` SV 方盘拖拽 | Stack：纯色相底 + 横向白→透明渐变 + 纵向透明→黑渐变 + 拇指；`onTouch` x/240→sat、1-y/160→val |
| `t8j` 色相条 | 彩虹渐变条 + 拇指；`onTouch` x/240×360→hue |
| `rw1.g("ColorPicker")` 子面板 | 独立 `bindSheet`（`showHsvSheet`），两入口共享 |
| `rw1.h` 选色应用 | `confirmHsvColor()`：target 分派 `pickTextColor`/`toggleHighlightColor` |
| `ax1` RemoveHighlight | 已有 `highlight_remove` 菜单项 |
| `xw1` EyeDropper | 画布取色器已移植（ADR-0646），文本面板入口登记差异 |

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/{base,zh_CN}/element/string.json`

## 验证

- `docs/migration/replays/d02-original-text-hsv-picker.mjs`：
  27 项静态钉全绿。
