# ADR-0236：按原版收口 Canvas 绘制状态事务

## 状态

Accepted - Phase 258（2026-08-17）

## 背景

M2-R-04 的 retained completed bitmap、最多 8 个独立 dirty region、按 zoom 换算 padding、临时
`ImageBitmap.close()` 与 transfer 统计实际上已在早期阶段落地；`修复总纲2.md` 中“每帧 transfer、单脏区、
临时 bitmap 未释放”的现场描述已过时，不能重复实现另一套缓存架构。

继续深审时发现真实剩余缺口：多个 Harmony renderer 使用 `save → transform/clip/alpha/draw → restore`，但
`restore()` 不在 `finally`。路径解析、纹理、bitmap 或 Canvas API 任一中途异常都会留下额外状态栈项；即使
外层下一次只恢复一次，也可能继续继承错误 transform、clip、alpha 或 composite mode。原版 1.0.3 `c5g`
在 splat、retained bitmap、普通 path 与 tape 路径均保证异常时恢复保存的 Canvas 状态。

同时复核 Phase 156 发现 `DirtyRectTracker` 声称“非法 zoom 回退 1”，实现却只判断 `zoom > 0`；正无穷会
被当成合法 zoom，使 `3 / zoom` padding 变成 0。

## 决策

- 主画布、缩略图、笔迹、局部擦除、文字、纸张、图形、图片和完成层合成中的每个绘制状态作用域，均在
  `save()` 后立即进入 `try`，并在对应 `finally` 中执行一次 `restore()`。
- 不捕获或吞掉渲染异常；与原版一致，只保证状态恢复后继续向上抛出，保留真实故障信号。
- `StrokeLayerManager` 的逐帧 transfer/dirty-region 统计在 `finally` 中归帧，失败帧不会把本帧 transfer
  错记到下一帧。
- 临时 isolated bitmap 的所有权保护从 `recordTransfer/drawImage` 之前开始；取得 bitmap 后无论统计或绘制
  是否失败都执行 `close()`。
- `DirtyRectTracker.markDirty()` 仅接受有限且大于 0 的 zoom；`NaN`、正负无穷和非正值统一回退 1。
- 不在本阶段猜测性修补 bounds。调用方仍必须提供页面坐标矩形；损坏元素的统一校验应在模型/持久化入口
  单独审计，不能让 dirty tracker 擅自决定“忽略”还是“整页重绘”。

## 后果

- 单次绘制失败不再污染后续主画布或缩略图的 transform、clip、alpha、filter、line dash 与 composite mode。
- 嵌套 renderer 各自恢复自己的状态层级，外层 `renderFrame` 的恢复不再承担清理未知深度泄漏的职责。
- 非有限 zoom 不会悄悄取消抗锯齿 padding；Phase 259 已把正常 viewport 范围按原版更正为 `[0.25, 10]`。
- M2-R-04 的静态代码项至此应记录为闭环：retained bitmap、multi-dirty、资源释放、transfer 统计与异常状态恢复
  均已有实现。500 笔帧时、10 分钟内存曲线、真实设备裁剪边缘和 native 峰值仍是运行态验收门，不能由 HAP
  编译或桌面 replay 代替。

## 验证契约

- `DirtyRectTracker.test.ets` 覆盖 `NaN/+Infinity/-Infinity` 回退后的页面 padding。
- `d02-original-canvas-state-restoration.mjs` 固定原版 `c5g/v0g` 证据、全部生产 renderer 的
  `save → try/finally → restore` 结构、isolated bitmap `finally close()` 与有限 zoom 条件。
- 全量桌面 replay、clean 后 `note@ohosTest` 与 `note@default` 必须通过；不启动设备、模拟器、虚拟机、
  真机或 Hypium。
