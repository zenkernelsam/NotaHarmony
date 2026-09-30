# ADR-1326 — CALLIGRAPHY 凿尖设置面板 + 每工具 STYLE 门控修正

- 状态：已接受
- 日期：2026-08（Phase 1390）
- 证据：`docs/migration/evidence/phase-1390-original-calligraphy-nib-settings.md`

## 决策

按 `k31.E()` 接口判定把 STYLE 行**收紧到仅 `n5h` 工具（PEN/HIGHLIGHTER）**，
并为 CALLIGRAPHY 补出原版 `ij1` 凿尖设置面板：

1. **STYLE 门控忠实**：新增 `supportsBrushStyleControls()` = PEN/HIGHLIGHTER，
   替换 `EditorToolbar` 的 `supportsBrushControls()` 门控。原 `k31.E` 以 `n5h`
   接口判定 STYLE——CALLIGRAPHY(`sri`)/SHAPE(`psi`)/PENCIL(`esi`)/REVIEW(`jsi`)
   均无 STYLE，旧实现误显。

2. **凿尖面板**：新增 `CalligraphyNibPanel.ets`——CALLIGRAPHY 激活时替换
   STYLE 行显示（`hri` 模型）。角度滑块 -60..60° 步15（9 档，
   `a0(15, ju7(-60,60,1))`），写回 `π/2+radians(offset)`、显示 `toDegrees(nibAngle-π/2)`；
   扁率 0.00..0.95 步0.05（20 档）+ Reset→0.75；Stabilization 开关。
   三 setter 经 `updateActiveState` 持久化 `tool_state.nib_angle/nib_flatness/
   stabilization`（migration 72 列）。

3. **防抖动 → 位置平滑**：`RenderSpec` 增瞬态 `stabilization`（不入 ink op）。
   `StrokeSession` 仅当 `spec.stabilization===true` 启用位置 EMA
   （`STABILIZATION_ALPHA=0.45`），作用于真实 commit 点；预测点保持瞬态。

## 显式差异（fail-open 近似）

原版 `aj1.nibStabilization` 驱动 Google Ink **位置平滑**（私有算法，反编译
不可得）。Harmony `ForceSmoother` 仅平滑压力，语义不符。故以**位置 EMA**近似：
不保证逐位还原原版平滑曲线，仅复刻「防抖开关 → 笔触位置去抖」的可观察行为。
预测点与已提交文档语义不受影响。
