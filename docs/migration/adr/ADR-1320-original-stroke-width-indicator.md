# ADR-1320：编辑器宽度按钮使用原版 strokeindicator 描边字形

## 状态

已接受（Phase 1384）。

## 背景

Harmony 编辑器工具栏的「粗细按钮」此前直接把当前宽度数值渲染成文本
（`Button(brushWidth.toString())`）。对照原版 `decompiled_1.0.3`，该按钮并不显示
数字，而是绘制一枚 **strokeindicator 向量字形**，同时编码「画笔样式」与「宽度档位」
两个维度。

## 原版证据

- `swd.java`：四个 `rwd` 样式族 `a/b/c/d` 分别对应 `y31` 序号
  `0=mono / 1=taper / 2=dash / 3=dot`；每个 `rwd` 持有三个 `qwd{fill,outline}`，
  对应 `size1/size2/size3`。
- `uwd.java`：宽度档位枚举 `SMALL(0)/MEDIUM(1)/LARGE(2)`。
- `x5f.java::c(a6f, float)`：取当前工具的宽度预设数组 `w4g.a.get(a6f)`，
  用 `x90.i0` 求最接近当前宽度的预设下标 `iI0`，`iMax=max(1, len/3)` 后三等分 —
  `iI0<iMax→SMALL`、`iI0<2*iMax→MEDIUM`、否则 `LARGE`。
- `z5c.java:1669/1688`：以 `swd.a(y31).a(uwd)` 取 `qwd`，先绘 `outline` 描边环
  （`ev1.b().c.a` 主题前景）、再叠 `fill` 内填充（`kkf.d(i5)` 画笔色）；
  无障碍文本为工具名（`ui_tools__pen`）。
- 24 个 `res/drawable/ui_tools__strokeindicator_<style>_size<N>_{fill,outline}.xml`
  已逐字提取（`viewport 24×6`，dash/dot 为多子路径已拼接）。

## 决策

1. 新增 `note/src/main/ets/ui/components/StrokeIndicators.ets`，导出
   `STROKE_INDICATORS`（`strokeind_<style>_<s|m|l>` → `{fill, outline, vw, vh}`），
   `pathData` 逐字保留。
2. `EditorToolbar` 新增 `strokeWidthTier()`（按 `widthWells` 最近预设三等分）、
   `strokeIndicatorKey()`（`BrushStyle` 序号 → 样式名）、`strokeIndicator()`。
3. 宽度按钮由「数字文本」改为 `Shape{outline 环(textPrimary) + fill(colorToHex(brush/selection))}`
   两层 Path，`viewPort 24×6` 缩放到 `32×8`。
4. 数值精度仍以 `.accessibilityText(当前宽度)` 保留给无障碍/读屏 —— 视觉与原版的
   抽象档位字形一致，宽度精确值改由无障碍文本与宽度滑杆承载。
5. `BrushStyle` 序号与 `y31` 完全一致（MONO/TAPER/DASH/DOT = 0/1/2/3），无需翻译层。

## 后果

- 宽度按钮视觉与原版对齐：样式与档位一眼可辨，且不随宽度连续值频繁跳动（仅档位变化）。
- 选择模式下使用 `selectionWidth`/`selectionColor` 取档与着色，与颜色按钮的选择态
  处理一致。
- 新增 Replay `d02-original-stroke-width-indicator.mjs`（28 断言）锁定样式映射、
  档位三分逻辑与两层渲染结构。

## 参考

- `docs/migration/evidence/phase-1384-original-stroke-width-indicator.md`
- `docs/migration/reports/phase-1384-original-stroke-width-indicator.md`
- `docs/migration/replays/d02-original-stroke-width-indicator.mjs`
