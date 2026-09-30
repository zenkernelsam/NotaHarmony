# Phase 1390 证据 — 1.4.2 CALLIGRAPHY 凿尖设置 + 每工具 STYLE 门控修正

> 源码证据：`decompiled_1.4.2`（1.4.2 APK，v1040002）。本 Phase 解决一个
> **1.4.2 迁移缺陷**：Phase 1388 已实现 CALLIGRAPHY 数据模型与渲染，
> 但缺其**专属凿尖设置面板**，且 STYLE 行被错误地显示给非 `n5h` 工具。

## 1. 每工具 settings 集的判定机制（k31.java）

`k31.java:66-82` — 工具设置集 `E(ToolType, ToolState)` 按 **接口判定**：

```
q92        → COLOR          fgg → WIDTH
n5h        → STYLE          sri → CALLIGRAPHY(nib面板)
wsi.e()    → tool 专属性: SHAPE_KIND / TAPE_PATTERN /
             SELECTION_MODE / ERASER_MODE / TAIL_MODE
```

- **STYLE 行 ⇔ `n5h`**。仅 `csi`(`eti.F` PEN) 与 `wri`(`eti.M` HIGHLIGHTER)
  实现 `n5h` → 仅 PEN/HIGHLIGHTER 显 STYLE 行。
- `sri`(`eti.G` CALLIGRAPHY) → `CALLIGRAPHY` 设置（凿尖面板 `hri`），**无 n5h**。
- `psi`(`eti.T` SHAPE) → `{SHAPE_KIND}`；`esi`(`eti.H` PENCIL) → `{COLOR,WIDTH}` 无 n5h；
  `jsi`(`eti.Q` REVIEW) → `{TAPE_PATTERN}`。

> **迁移缺陷**：Harmony 旧实现以 `supportsBrushControls()`（含 CALLIGRAPHY/SHAPE/
> PENCIL/REVIEW）门控 STYLE 行 → 4 个工具错误显式。本 Phase 改以
> `supportsBrushStyleControls()`（仅 PEN/HIGHLIGHTER）门控。

## 2. CALLIGRAPHY 凿尖面板（hri/ij1/pxi/aj1）

`ij1.java` — CALLIGRAPHY 设置 composable（`hri` 模型驱动）：

| 控件 | 原版图元 | 值域 | 语义 |
|------|----------|------|------|
| 角度滑块 | `o6k.a0(15, ju7(-60,60,1))` | **-60°..+60° 步 15°（9 档）** | `wp(int°)` → `nibAngle` |
| 扁率滑块 | `a0(20, ju7(0,0.95,0.05))` | **0.00..0.95 步 0.05（20 档）** | `is5(float)` → `nibFlatness` |
| Reset | `r0d`/按钮 | — | 恢复扁率默认 0.75 |
| Stabilization | `c(label, z, pxi)` | 布尔 | `g0c(bool)` → `nibStabilization` |

- `q6i.java:117` 角度显示 = `Math.toDegrees(nibAngle - π/2)`（相对竖直偏移）。
- `aj1.c` `CalligraphySelection(nibAngle, nibFlatness, nibStabilization)` 存于
  `ToolStateEntity`（Phase 1389 migration 72 已加 `nib_angle`/`nib_flatness`/
  `stabilization` 列）。
- `zmb.java` CALLIGRAPHY 种子 `stabilization=1`（默认开）。

## 3. Harmony 实现映射

| 原版 | Harmony |
|------|---------|
| `k31.E` n5h→STYLE | `supportsBrushStyleControls()` = PEN/HIGHLIGHTER |
| `ij1` 凿尖面板 | `CalligraphyNibPanel.ets`（角度/扁率/Reset/防抖） |
| `wp(int°)` | `setCalligraphyNibAngle(π/2+radians(offset))` |
| `is5(float)` | `setCalligraphyNibFlatness(f)`（0..0.95 步0.05） |
| `g0c(bool)` | `setCalligraphyStabilization(0/1)` → `tool_state.stabilization` |
| `aj1.c.nibStabilization` | `RenderSpec.stabilization` → `StrokeSession` 位置 EMA |

## 4. 防抖动的语义边界

原版 `aj1.nibStabilization` 是 **Google Ink 位置平滑** 开关（内部私有算法）。
Harmony `ForceSmoother` 仅平滑**压力**。本 Phase 在 `StrokeSession` 加入
**位置 EMA**（`STABILIZATION_ALPHA=0.45`），仅当 `spec.stabilization===true`
启用，作用于真实 commit 点；预测点保持瞬态不入档。**算法为边界内近似**，
ADR-1326 记 fail-open 近似（非逐位复刻）。
