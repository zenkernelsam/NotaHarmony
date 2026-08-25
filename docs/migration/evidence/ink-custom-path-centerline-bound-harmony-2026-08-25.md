# Harmony 证据：显式墨迹轮廓中心线绑定

- 日期：2026-08-25
- 基准：1.0.3 `defpackage/nwd.java` 将字段命名为 `path=CentralPathStrokeContent.path`、`customPath`；`defpackage/e16.java` 在中心线分支中先 `clipPath(path8/path10)`（即 customPath），随后用已设置宽度、cap/join/dash/color 的 paint 绘制 `nwd.c()` 中心线。
- 缺陷：Harmony `renderCustomPath()` 曾按样式分流：DASH/DOTS 才裁剪，其余样式把 customPath 当作填充路径。这会把 MONO/FIXED_WIDTH/VARIABLE_WIDTH/highlighter 显式轮廓渲染为实心形状，并丢失原版线帽与荧光 alpha 语义。
- 修复：所有中心线样式先 append customPath 并 clip，然后调用 `renderCenterPath()`；移除 customPath 分支中的 setFillStyle/fill。铅笔专用 splat 渲染不变。
- Replay：
  - 新增 `d02-ink-custom-path-centerline-bound.mjs`：11/11。
  - 相邻 auxiliary paths、render、style map、ink effects、partial eraser、create ink、modify pencil Replay 全部通过。
  - ArkTS 检查 `Canvas2DStrokeRenderer.ets` 无诊断。
