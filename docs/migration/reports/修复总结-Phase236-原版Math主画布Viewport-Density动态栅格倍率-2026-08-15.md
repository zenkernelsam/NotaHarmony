# Phase 236 修复总结：原版 Math 主画布 Viewport-Density 动态栅格倍率

## 发现

Phase 235 修正编辑器 preview 的 Density 像素契约后，继续检查 standalone Math block 的主画布与缩略图路径，
确认 `MathCanvasRenderer` 仍统一固定 `pixelScale=2`。这不是原版的质量策略：

- 3× Density、100% zoom 时，原版会使用 3×，旧 Harmony 只有 2×，最终仍需放大低分辨率公式；
- 2× Density、200% zoom 时，原版会 clamp 到 4×，旧 Harmony 同样只有 2×；
- 缩略图的 page-to-output scale 通常低于 1，原版 clamp 后只需要 1×，旧 Harmony 却始终分配 2×；
- 固定 2× 既造成高倍率模糊，也让 4 MiB Math LRU 在低倍率 consumer 中更快被无意义的大 bitmap 挤出。

普通 JADX 输出缺失 `aeg.invokeSuspend()` 与 `ue4.v()`，不能直接解释两个 float 参数。使用 JADX 1.5.6
单类 fallback/simple 重新线性反编译后，参数和公式均得到闭环，不再依赖猜测。

## 原版依据

- `t0g.toString()`：`a` 明确命名为 `ViewportState.zoom`，`f` 明确命名为 `density`。
- `r93.a()` 返回 Density；`r93.j0()` 的逻辑到物理转换是 `a() * value`。
- `aeg.invokeSuspend()` fallback：调用 `ue4.v()` 前读取 `t0g.a` 与 `t0g.f.a()` 作为两个 float。
- `ue4.v()` simple：
  `m18.y0(rh8.u(zoom * density, 1.0f, 4.0f) * 2.0f) / 2.0f`。
- `m18.y0()` 是 float `Math.round()`，`rh8.u()` 是闭区间 clamp，因此倍率范围是 1–4，步长是 0.5。
- 量化结果经 `G → E` 进入 standalone bitmap renderer；`E` 的缓存键包含同一 scale，`p18` 用它创建 bitmap
  并缩放 Canvas。
- APK SHA-256、JADX 命令与最小寄存器摘录已固化到
  `docs/migration/evidence/original-math-raster-scale-jadx-2026-08-15.md`。

## 修复

- 在 `MathCanvasRenderer` 新增 `originalMathRasterScale()`：
  - zoom、Density 与乘积逐步 `Math.fround()`，保持原版 Float32 边界；
  - clamp 到 1–4；
  - 按 `round(scale * 2) / 2` 量化为 0.5 步长；
  - 非有限或非正 Harmony 平台输入安全回退 1×，不把异常数值送入 Native。
- `renderMath()` 改为显式接收 raster scale；同一个 Float32 值同时进入 cache key 和
  `OriginalMathEngine.render()`。
- 主画布每次有序绘制时使用 `originalMathRasterScale(this.viewport.zoom, vp2px(1))`，读取当前 zoom 与当前
  ArkUI Density。
- 缩略图使用 `originalMathRasterScale(pageTransform.scale, 1)`；300×400 输出坐标已经表达目标像素缩放，
  不再重复叠加当前屏幕 Density。
- 保留 4 MiB byte-counted LRU、oversized transient texture、LRU eviction 与 ImageBitmap/PixelMap 释放协议。
- 新增 `MathCanvasRenderer.test.ets`，覆盖 Density 乘积、Float32 半步边界、上下 clamp 和异常平台输入；并接入
  `List.test.ets`。
- 新增专项 replay，锁定原版字段语义、JADX 寄存器证据、Harmony 两个 consumer 接线、缓存身份和运行时数值模型。
- 更新 box-fit replay 的旧固定常量断言，并在 Phase 230 历史总结中更正“2× 是原版固定契约”的潜在误读。
- 新增 ADR-0213。

## 边修边审新发现

含原版 partial eraser 时，`renderOrderedContentLayer()` 会把所有元素先画入整页 `OffscreenCanvas` 再合成到主画布。
即使 Math source bitmap 已按目标 `zoom × Density` 生成，该公共离屏层仍可能在放大时成为包括 Math、Text、Shape
在内的最终栅格分辨率瓶颈，并带来整页临时分配成本。原版采用 tile renderer，不是每帧整页扁平化。

这一项涉及所有元素的隔离合成、擦除语义、可见区域裁剪和内存预算，不宜在 Math scale 小修中无证据扩张；已保留为
下一批边修边审候选。

## 修改文件

- `note/src/main/ets/rendering/MathCanvasRenderer.ets`
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- `note/src/main/ets/rendering/ThumbnailRenderer.ets`
- `note/src/test/MathCanvasRenderer.test.ets`
- `note/src/test/List.test.ets`
- `docs/migration/evidence/original-math-raster-scale-jadx-2026-08-15.md`
- `docs/migration/replays/d02-original-math-raster-scale.mjs`
- `docs/migration/replays/d02-original-math-box-fit.mjs`
- `docs/migration/adr/ADR-0213-original-math-viewport-density-raster-scale.md`
- `docs/migration/reports/修复总结-Phase230-原版Math-Float32框适配与Native参数-2026-08-15.md`
- `docs/migration/reports/修复总结-Phase236-原版Math主画布Viewport-Density动态栅格倍率-2026-08-15.md`

## 验证

- raster-scale 专项 replay：`TOTAL=15 FAILED=0`。
- 更新后的 Math box-fit replay：`TOTAL=18 FAILED=0`。
- 全部 Math replay：`MATH_REPLAY_FILES=26 FAILED=0`。
- 全量桌面 replay：`REPLAY_FILES=223 FAILED=0`。
- `hvigorw clean --no-daemon`：`BUILD SUCCESSFUL in 2 s 211 ms`。
- clean 后 `note@ohosTest assembleHap`：`OhosTestCompileArkTS` 实际执行并通过，
  `BUILD SUCCESSFUL in 7 s 359 ms`。
- 同一次 clean 后 `note@default assembleHap`：Native Ninja、`CompileArkTS` 与 PackageHap 通过，
  `BUILD SUCCESSFUL in 32 s 857 ms`。
- `git diff --check` 通过；仅有项目既有 LF→CRLF 提示和既有 ArkTS warning。
- 未启动设备、模拟器、虚拟机或 Hypium。

## 真机待测

- 在 1×/2×/3× Density 上分别以 25%、50%、100%、150%、200%、400% zoom 查看同一公式，核对倍率阶梯、
  字体边缘、分数线、根号、上下标和最右/下边缘裁切。
- 跨越 1.25、1.75、2.25 等半步阈值缓慢 pinch，确认 bitmap 只在原版阈值切换且缓存不会每帧抖动。
- 比较普通主画布路径与含 partial eraser 的整页离屏路径，判断后者是否仍出现统一模糊或内存峰值。
- 检查缩略图 Math 清晰度与生成耗时，确认从固定 2× 降到原版最小 1× 后没有输出像素回归。
- 在运行中切换窗口/显示 Density 后触发重绘，确认使用新 Density 且旧 scale cache 条目按 LRU 正常释放。
