# 原版 DASH/DOTS 虚线相位渲染 — Harmony 证据文档

- 日期：2026-09-22
- Phase：574
- 结论：已修复（Harmony 曾把 `backingDashPhase` 当虚线相位渲染偏移，
  原版两处 Java 渲染器均恒用 `0.0f`；该字段仅服务特效相位与切片推进）

## 原版证据（decompiled_1.0.3）

### 两处 DashPathEffect 均恒用 0.0f 相位

- `c5g.java:207-240`（`c5g.g`，实时/矢量墨迹路径）：
  - `t16.DASH` → `new DashPathEffect(new float[]{2.0f*w, 1.0f*w}, 0.0f)`，
    宽度为键入 LruCache；
  - `t16.DOTS` → `new DashPathEffect(new float[]{0.001f*w, 2.0f*w}, 0.0f)`；
  - 两处 phase 参数均为字面量 `0.0f`。
- `e16.java:119-151`（InkRenderer 持久笔画分支，`nwd` 渲染项 →
  `p16.centralPathPaint`）：
  - ordinal 2（DASH）→ BUTT cap + ROUND join + `DashPathEffect([2e,1e], 0.0f)`；
  - ordinal 3（DOTS）→ ROUND cap + MITER join + `DashPathEffect([0.001e,2e], 0.0f)`；
  - 其余 → ROUND/ROUND 且无 PathEffect。HashMap 缓存键同样只有宽度。

### 画笔 cap/join 表（`c5g.java:28-62` 构造器）

| Paint | 用途 | Style | Cap | Join | BlendMode |
|---|---|---|---|---|---|
| `f` | 实线默认 | FILL | — | — | SRC_OVER |
| `g` | 轮廓填充 | FILL | — | — | SRC_OVER |
| `h` | f2 覆盖宽描边 | STROKE | ROUND | ROUND | SRC_OVER |
| `i` | DASH | STROKE | BUTT | ROUND | SRC_OVER |
| `j` | DOTS | STROKE | ROUND | MITER | SRC_OVER |

Harmony `renderCenterPath` 的 cap/join 选择（DASH→butt、DOTS→miter、其余
round/round）与该表逐项一致。

### 高亮 alpha 覆盖（非 blend-mode）

- `c5g.java:248-250`：`if (z) { i = zx1.e(i, 107); }`——`z` 为
  isHighlighter，`zx1.e`（`zx1.java:39-44`）= `(i & 0xFFFFFF) | (107 << 24)`，
  **替换** alpha 而非相乘；所有 paint 均为 `BlendMode.SRC_OVER`。
- Harmony `colorToRgba(color, 107)` 的覆盖语义与之精确一致；审计清单
  1.1 中「高亮混合模式是近似」的疑点由此澄清：原版本来就只有 alpha，
  不存在 MULTIPLY 等待移植的混合模式。

### `backingDashPhase` 的真实消费方

- `yyd.java:53-60`：StyleMap 线格式 =
  `backingPencilSeed@0(int)` + `backingPencilReferencePoint@4(fqa)` +
  `backingDashPhase@12(float)` + `backingDashPeriod@16(float)`；
  Harmony `OriginalInkStyleMapCodec` 布局一致。
- `s06.java:396-397`、`qee.java:82-87`、`o0j.java:566`、
  `a1j.java:191`、`laj.java:101`、`n5d.java:228`：所有 `d()`
  （backingDashPhase）读取点都只流入 `rz1.H(phase, effectsMask, tinted)`。
- `rz1.java:174-189`：`H()` 把相位装进 `l06`（InkEffectSpec）。
- `l06.java:36`：`toString` = `InkEffectSpec(effect, tinted,
  phaseOffsetPx)`——相位是 RAINBOW/GLITTER 特效（`k06`）的
  `phaseOffsetPx`，供 WetMirror/native 特效着色器定位，
  **不进入任何 Java PathEffect**。
- `ft1.java:78-94`（切片/变换）：仅当 `t16` ordinal ∈ {2,3}
  （DASH/DOTS）时产出 `uyd("Dash(phase)")` 载体，
  `phase = ((distance + basePhase) % period + period) % period`，
  `period` 由 `n8j.java:611-624` 按 `[2w,1w]`/`[0.001w,2w]` 求和 =
  `3w`/`2.001w`；`o8j.java:160-165` 将 `uyd.I` 写回新 StyleMap
  （保留 `backingDashPeriod`，重置 pencil 字段）。
- `backingDashPeriod`（`yyd.c()`）无渲染消费方（仅 hashCode/toString），
  属保真留存的 wire 字段。

### 差异定位

Harmony `renderCenterPath` 曾执行
`setLineDashOffset(styleMap[0].backingDashPhase % period)`：
- 对切片/导入的 DASH/DOTS 笔画（backingDashPhase ≠ 0）会把虚线图案
  沿路径平移——原版 Java 渲染层从不产生此偏移；
- 对新建笔画（phase=0）无可见差异，故长期未暴露。

## Harmony 对齐

- `Canvas2DStrokeRenderer.renderCenterPath`：移除 `setLineDashOffset`
  块，虚线相位恒为 0（与 `DashPathEffect(intervals, 0.0f)` 等价），
  并加注释钉住证据。
- `backingDashPhase`/`backingDashPeriod` 仍由 StyleMap codec 无损往返、
  由 `OriginalInkPartialEraser.remnantStyleMap` 按 `ft1` 同式推进、
  由 `RenderSpec.inkEffectPhase`（ADR-0046）为特效保留——仅渲染消费方
  被移除。
- `renderInkFill` 的半透明填充排除 clip ≈ `e16` 的 `clipOutPath`
  （`e16.java:166-178`）；`renderCustomPath` 的 DASH/DOTS「先 clip
  customPath 再描中心线」≈ `e16.java:186-190`——均核对一致。

## 验证

- `d02-original-dash-phase-zero.mjs`：16/16（钉住相位为 0、cap/join、
  alpha-107、切片推进式不变量）。
- `d02-modify-ink-style-map.mjs`：旧断言「渲染器消费 backingDashPhase」
  已更新为「renderCenterPath 不含 setLineDashOffset 调用」。
- 全量 replay 与双 HAP 构建见 Phase 574 报告。

## 遗留边界

- `zea`（PencilSplatRenderer，SharedMemory RGBA_F16 splat 位图）与
  androidx.ink/WetMirror 原生层的系统性对照仍属域4 遗留大项；
  `backingDashPhase` 若在原生特效层另有消费，不构成本修复的回归源
  （Harmony 本就 fail-closed 特效着色，见 ADR-0046）。
