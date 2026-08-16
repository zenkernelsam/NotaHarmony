# Phase 259 修复总结：原版 Viewport 缩放范围与按钮步进

## 基线与目标

- 基线提交：`60a1e1a fix(rendering): restore canvas state on failures`
- 目标：重放 `修复总纲2.md` 的 M2-R-05，严格参考原版 1.0.3，统一 viewport 交互、恢复、适宽与
  持久化范围，修复 T-034 工具栏按钮把固定步进误当倍率的漂移，并拒绝损坏视图状态写入数据库。
- 本阶段不启动设备、模拟器、虚拟机、真机或 Hypium。

## 现场重放结论

M2-R-05 的共享 screen/canvas 映射、1000 点往返、缩放锚点、累计 pinch/pan 差分、整页页面坐标与
纸张渲染早已有核心实现。本阶段没有重写坐标架构，而是发现并修复三个仍会直接改变体验或数据的缺口：

1. `CanvasViewport` 仍沿用早期 T-034 自定的 4×上限，而原版 viewport 是 0.25×～10×。
2. T-034 规定 `+/-` 按钮每次步进 0.25，旧实现却把 `delta` 作为 `1 + delta` 倍率，连续点击产生
   100%→125%→156%→195%，并非 100%→125%→150%→175%。
3. `NoteRepositoryImpl.saveViewState()` 只检查坐标模型版本，仍可能把 NaN、Infinity、范围外 zoom 或
   非有限 scroll 写入 `note_state`。

## 原版证据

- `t0g.java:34-36`：`ViewportState` 使用 `new ms1(0.25f, 10.0f)`。
- `h3a.java:35-42`：交互 zoom 为 `clamp(oldZoom * factor, 0.25, 10)`，再以 clamp 后的实际倍率和调用方
  锚点更新 translation。
- `v0g.java:75-101`：持久化 zoom 与 scroll 分别校验、分别丢弃损坏值；zoom 合法范围同样为
  `[0.25,10]`。
- `x0f.java:337-447`：任何非有限 viewport state 或派生 doc offset 均拒绝持久化。
- `d2.java:193/383`：原版键盘 zoom 使用 1.2/0.8333333 互逆倍率；它不是 Harmony T-034 的固定 0.25
  按钮规格，因此本阶段没有把两者伪称为相同交互。

证据文件及 SHA-256 见
`docs/migration/evidence/original-viewport-zoom-range-and-step-jadx-2026-08-17.md`。

## 实际修改

### 单一 viewport 范围与校验器

`NoteTypes.ets` 新增：

- `ORIGINAL_VIEWPORT_MIN_ZOOM = 0.25`；
- `ORIGINAL_VIEWPORT_MAX_ZOOM = 10.0`；
- `isOriginalViewportZoom()`；
- `isFiniteViewportScrollOffset()`。

`CanvasViewport.setZoomRaw()`、`zoomAt()`、`visibleCanvasRect()` 与 clamp 均复用同一范围。当前 zoom 已损坏
或 scroll 非有限时，缩放和可见区计算不再继续传播坏状态。`NoteCanvasView.fitWidth()` 也复用同一常量，
避免 UI、viewport 与 repository 各自维护不同上限。

### 分离 pinch 倍率与按钮加法步进

`zoomAt(anchor, factor)` 保持原版倍率语义，并继续按 clamp 后实际倍率保持锚点下页面点不动。新增
`stepZoomAt(anchor, delta)` 专供 T-034 工具栏：先计算 `oldZoom + delta`，再换算成实际倍率复用
`zoomAt()`。pinch 仍直接传倍率，不受按钮规格影响。

因此按钮序列恢复为 100%→125%→150%→175%，到 25%/1000% 边界时不越界，视口中心锚点保持稳定。

### 持久化写入门禁与恢复边界

`NoteRepositoryImpl.saveViewState()` 在取得全局数据库写锁前拒绝：

- 非有限或不在 0.25×～10×内的 zoom；
- X/Y 任一非有限的 scroll offset；
- 原有坐标模型版本不匹配。

UI 恢复仍分别调用 `setZoomRaw()` 与 `setScroll()`，保留原版字段级容错：坏 zoom 不阻止合法 scroll，坏
scroll 也不撤销合法 zoom。

## Fixture / replay

- `CanvasViewport.test.ets`：
  - 1000 个随机点覆盖 0.25×～10×的 screen→canvas→screen 往返；
  - 1000 个随机锚点覆盖完整范围；
  - 100%→125%→150%→175% 加法序列；
  - 25%/1000% clamp、NaN/±Infinity 与损坏 visible rect。
- `PageCoordinateSpace.test.ets`：25/100/400/1000% 坐标往返及 0.25×→10×锚点。
- `DatabaseHelper.test.ets`：zoom/scroll validator 的闭区间与非有限值。
- 新增 `d02-original-viewport-zoom-range.mjs`，固定原版证据、Harmony 接线与数值模型。

专项结果：

- Viewport 新专项：`TOTAL=26 FAILED=0`；
- Canvas 状态专项：`TOTAL=17 FAILED=0`；
- PDF 可见区专项：`TOTAL=13 FAILED=0`；
- Tape 缩放专项：`TOTAL=18 FAILED=0`；
- Math 主画布倍率专项：`TOTAL=15 FAILED=0`；
- 全量桌面 replay：`REPLAY_FILES=244 FAILED=0`。

## 最终验证

- 修改中增量 `note@ohosTest`：`BUILD SUCCESSFUL in 6 s 942 ms`。
- `hvigorw --no-daemon clean`：`BUILD SUCCESSFUL in 3 s 357 ms`。
- 同一次 clean 后 `note@ohosTest`：`BUILD SUCCESSFUL in 8 s 648 ms`。
- 同一次 clean 后 `note@default`：`BUILD SUCCESSFUL in 31 s 956 ms`。
- `git diff --check` 通过；只有工作树既有 LF→CRLF 提示。
- 构建只有项目既有 ArkTS/deprecation warning 与未配置 signing 提示。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 仍需设备验收

- 25/100/400/1000% 下真实 pinch、双指平移、按钮、适宽、重开恢复与百分比显示；
- 1000% 下 completed bitmap、PDF 边缘、Tape 8× bucket、Math 4× bucket、文字、形状和图片清晰度；
- 快速跨缩放上下限时的锚点手感、PDF debounce、缓存切换、LRU 抖动及 native/JS 内存峰值。

10× viewport 只证明交互和坐标范围已经对齐，不等于所有 consumer 都必须或已经分配 10× raster；Tape、Math、
PDF 与 completed bitmap 继续保持各自经证据确认的质量和资源边界。

## Goal 纪律

T-042 APK 版本追踪仍严格留到整个 Goal 最后。本阶段只继续登记该延期约束；最终必须自行建立版本追踪文档/
工具并另写中文 Report，明确说明建立了什么、功能、入口与用法，再把阅读顺序和新版 APK decompile/diff
流程归纳进 Wiki、技术文档、API 文档与新手入门。
