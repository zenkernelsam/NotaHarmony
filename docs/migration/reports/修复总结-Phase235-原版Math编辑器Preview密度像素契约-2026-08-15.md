# Phase 235 修复总结：原版 Math 编辑器 Preview 密度像素契约

## 发现

Phase 234 恢复 Native 四态与 preview 后，继续沿 `axi → w08 → p18` 追踪渲染参数，发现“280×96、1×”仍被
少移植了一层：

- Harmony 把 280、96 直接当成 bitmap 像素；
- 原版的 280、96 是 Compose dp，`axi` 先通过 Density 转成物理像素；
- 原版 `p18` 的 `scale=1` 发生在 Density 转换之后，不代表 bitmap 永远只有 280×96 像素。

因此在 2×/3× 屏幕上，Harmony 会把 280×96 低分辨率公式拉伸到 560×192 / 840×288 物理显示区域，造成
文字、根号、分数线和透明边缘模糊。若只把 `pixelScale` 改成 Density，又会改变原版 measure/fit/ceil 的运算顺序。

## 原版依据

- `v08`：preview layout 固定 280dp 宽、96dp 高。
- `axi.a()`：从 CompositionLocal 取得 `r93`，调用 `j0(280.0f)` 与 `j0(96.0f)` 后才创建 `w08`。
- `r93.j0(float f)`：明确返回 `a() * f`，其中 `a()` 是当前 Density。
- `w08`：把已经转换的物理宽高连同独立 `1.0f` scale 交给 `p18`。
- `p18`：bitmap 尺寸为 `ceil(width * scale)` / `ceil(height * scale)`，Canvas 再执行同一 scale。

这证明原版 3× 屏幕的 preview 目标接近 840×288 像素，而不是把 280×96 bitmap 放大显示。

## 修复

- 将常量命名明确为 `ORIGINAL_MATH_EDITOR_PREVIEW_WIDTH_VP` 与
  `ORIGINAL_MATH_EDITOR_PREVIEW_HEIGHT_VP`。
- 每次 Native validation 开始时调用 `vp2px(280)` / `vp2px(96)`，读取当前 ArkUI Density 对应的物理框。
- Density 转换结果非有限或非正时直接进入 Invalid，不向 Native 申请异常 bitmap。
- `OriginalMathEngine.render()` 接收转换后的物理宽高，同时继续保持原版独立 `pixelScale=1`，避免双重放大。
- 更新四态 replay，使其同时锁定逻辑尺寸、Density 转换和 post-density 1× scale。
- 新增 Density preview 专项 replay，逐项锁定 `axi/r93/p18` 证据、Harmony 接线和 1×/2×/3× 数值模型。
- 新增 ADR-0212，并更新 ADR-0124/0211；在 Phase 234 总结中追加后续更正，保留历史可追溯性。

## 修改文件

- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- `docs/migration/replays/d02-original-math-editor-four-state.mjs`
- `docs/migration/replays/d02-original-math-editor-density-preview.mjs`
- `docs/migration/adr/ADR-0124-original-math-latex-editing.md`
- `docs/migration/adr/ADR-0211-original-math-editor-native-four-state-preview.md`
- `docs/migration/adr/ADR-0212-original-math-editor-preview-density.md`
- `docs/migration/reports/修复总结-Phase234-原版Math编辑器Native四态与预览-2026-08-15.md`
- `docs/migration/reports/修复总结-Phase235-原版Math编辑器Preview密度像素契约-2026-08-15.md`

## 验证

- Density preview 专项 replay：`TOTAL=15 FAILED=0`。
- 原版 Math 编辑器四态 replay：`TOTAL=30 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=25 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=222 FAILED=0`。
- `note@default assembleHap`：`CompileArkTS` 实际重新执行并通过，`BUILD SUCCESSFUL in 10 s 571 ms`。
- `note@ohosTest assembleHap`：`OhosTestCompileArkTS` 实际重新执行并通过，
  `BUILD SUCCESSFUL in 6 s 964 ms`。
- `git diff --check` 通过。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 在不同 Density 的设备上确认 preview bitmap 实际尺寸约为 280×96、560×192、840×288。
- 比较原版分数线、根号、上下标、小字号文字和最右/下边缘在高密度屏的清晰度与裁切。
- 验证窗口尺寸变化、主题切换和重新打开编辑器时使用当前 Density，且旧 preview 资源正常释放。
- 多显示器或运行中 Density 变化是否触发 area/configuration 更新仍需设备确认。
