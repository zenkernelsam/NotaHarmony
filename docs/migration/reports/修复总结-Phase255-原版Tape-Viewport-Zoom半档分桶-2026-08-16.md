# Phase 255 修复总结：原版 Tape Viewport Zoom 半档分桶

## 目标

结束 Phase 155 因缺少可靠 zoom 上下文而暂缓的 Tape pattern scale bucket。严格按原版 1.0.3 恢复
pattern cell 的分辨率、缓存身份和 consumer 传参，同时不把现有整页完成层的高倍栅格限制混写为已解决。

## 原版证据与更正

- `c5g.java:275-281` 从名为 `zoom` 的 `Function0` 读取 float，并作为 `qfe.a()` 第六参；排除 brushWidth
  与显示 Density。
- `qfe.java:60-63` 使用 `round(clamp(zoom,1..8)×2)`，并以
  `pattern + overlayColor + FLOWERS专用tapeColor + scaleBucket` 查询 32 项 LRU。
- `mfe.java:34` 的 `PatternCellKey` 字符串确认上述四字段身份。
- `qfe.java:120-126` 以 `bucket/2` 创建 bitmap；`qfe.java:551-561` 又把 bitmap 映射回固定逻辑 cell。
  因此 bucket 改变像素密度，不改变页面中的 pattern 重复周期；这更正了 Phase 155 ADR 的旧表述。
- APK SHA-256 与逐行摘录已固化到
  `docs/migration/evidence/original-tape-viewport-zoom-bucket-jadx-2026-08-16.md`。

## 代码修复

- `Canvas2DStrokeRenderer` 新增 `originalTapePatternScaleBucket()`：
  - zoom 先收窄为 Float32；
  - clamp 到 1～8；
  - `round(scale×2)` 得到 2～16 的整数 bucket，即 1×～8×、0.5×步进；
  - 非有限或非正 Harmony 输入安全回退 bucket 2（1×）。
- 新增 `originalTapePatternPixelSize()`，按 Float32 logical-size 乘 bucket scale 后 round，恢复原版 cell
  bitmap 尺寸。
- 删除固定 `TAPE_TILE_DENSITY=8`；cache key 改为
  `pattern:overlayColor:effectiveTapeColor:scaleBucket`。只有 FLOWERS 使用 Tape 本色，其他图案保持 0。
- 保留 32 项 LRU、命中提升、逐项 eviction close 与 renderer dispose 全量 close。
- `StrokeCanvasPainter` 把 viewport zoom 作为显式只读参数传到 Tape renderer；mask 隔离、普通 stroke 与
  AudioLinked 原/高亮片段共用同一倍率。
- `StrokeLayerManager` 的 commit、普通 composite、full composite、current stroke 与 rebuild 全部透传 zoom。
- `NoteCanvasView` 所有完成层 rebuild、直接有序绘制、当前笔迹、AudioLinked 与 full composite 使用
  `this.viewport.zoom`，避免某条 mutation/Undo 路径悄悄退回 1×。
- `ThumbnailRenderer` 使用 `pageTransform.scale`，因为缩略图的 page-to-output transform 就是该 consumer
  的输出倍率；不重复叠加当前显示 Density。

## 边修边审结论

固定 8× 在 1× 下会让 cell 像素面积达到原版的 64 倍。例如 30×13 的 STARS cell 旧实现分配
240×104，原版 1× 只需 30×13；动态 bucket 恢复原版缓存占用与阈值切换。

但已完成 stroke 仍先被压入页面尺寸 `completedLayer`，随后随 viewport 放大。即使 Tape source cell 使用正确
bucket，整页 cache 仍可能成为所有完成元素的最终高倍分辨率瓶颈。此问题应在 M2-R-03/04 中结合可见区域、tile、
partial eraser 合成和内存预算整体设计；本阶段没有用“每次 zoom 重建整页 8× bitmap”制造更危险的假修复。

## 测试与验证

- ArkTS `RendererStyle.test.ets` 新增原版 bucket fixture，覆盖：
  - 1.25/1.75 首两档阈值；
  - 1×/8× clamp；
  - NaN/Infinity 安全回退；
  - 8×8 与 11.313708×11.313708 cell 的 Float32 像素尺寸。
- 专项 replay：`D02_ORIGINAL_TAPE_SCALE_BUCKET_REPLAY_OK TOTAL=18 FAILED=0`。
- 更新后的基础 Tape replay：
  `D02_ORIGINAL_TAPE_REPLAY_OK ... zoom-bucketed-repeat-cache=32 ...`。
- 全量桌面 replay：`REPLAY_FILES=240 FAILED=0`。
- `hvigorw --no-daemon clean`：`BUILD SUCCESSFUL in 1 s 954 ms`。
- clean 后 `note@ohosTest`：`BUILD SUCCESSFUL in 51 s 806 ms`。
- 同一次 clean 后 `note@default`：`BUILD SUCCESSFUL in 2 s 917 ms`。
- `git diff --check` 通过，仅有项目既有 LF→CRLF 提示与既有 ArkTS warning。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 未闭环

- 在 1×/2×/3× Density 设备上，缓慢跨越 1.25、1.75、2.25 等 zoom 阈值，核对图案边缘、重复接缝和
  阈值切换是否与原版一致。
- 在 Phase 259 恢复的 1000% viewport 上确认仍使用原版 8× bucket、不会生成 10× cell，并比较当前笔迹与
  完成层的最终清晰度。
- 监测快速 pinch 时的 LRU 命中、ImageBitmap 创建/close、峰值内存和帧时间，确认不会在相邻 bucket 抖动。
- 比较当前笔迹、完成层、AudioLinked、partial eraser ordered redraw 与缩略图，确认同倍率下图案相位与清晰度一致。
- 整页完成层的高倍统一模糊与大页面内存上限继续属于 M2-R-03/04，不在本阶段关闭。

## Goal 纪律

T-042 APK 版本追踪仍严格是整个 Goal 的最后一项。最终建立追踪文档／工具时必须另写中文 Report，明确说明
建立了什么、解决什么问题、入口和使用方法；随后把其用途、阅读顺序、新版 APK decompile/diff 流程归纳进
Wiki、技术/API 文档和新手入门，新手入门需直接告诉首次参与者何时使用以及从哪里进入。
