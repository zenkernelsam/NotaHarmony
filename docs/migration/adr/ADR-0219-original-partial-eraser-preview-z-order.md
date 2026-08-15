# ADR-0219：Partial-eraser preview 作为最新 Ink 覆盖完整有序内容

## 状态

Accepted，2026-08-16。修正 ADR-0218 的原 dirty-crop 分层条款。

## 背景

ADR-0218 已正确恢复 transient tool-5 preview 的生命周期，但当时把普通 Stroke→Text 页面优化为“只擦
completed handwriting crop，再把 Text 无条件重画到前景”。继续追踪 `n1d/fsi/xq9/s06/vnd/aa6/aeg` 后确认：
新 tool-5 CREATE_INK 使用当前 clientTime/Realtime 作为排序时钟，属于普通 z-index 内容；原版 tile renderer
又会把 Ink、Shape、Image、Text 与 Math 作为同一有序流交错生成命令。因此活动 preview 位于所有既有页面内容
之后，Text 也应在手势经过时暂时被覆盖。

## 决策

1. `materializePageElements()` 接受可选 `transientTopStroke`。它只在返回的渲染数组末尾追加 preview，不修改
   durable `elementOrder`、snapshot、operation log 或 history。
2. 只要存在 partial-eraser preview，主画布统一调用
   `StrokeLayerManager.compositeWithOrderedPartialEraser()`；不再保留 handwriting-only/Text-foreground 快速路径。
3. manager 继续使用累计 dirty bounds，但每个 crop 都建立透明 OffscreenCanvas，并由调用方在其中重绘完整
   Stroke/Text/Shape/Image/Math 顺序，最后绘制 transient tool-5 Ink。
4. Paper/background 在主画布 crop 上单独恢复，因此 destination-out 只揭示纸张，不会把主画布挖透明。
5. `forceFull` 仍先清理整个 viewport，随后 manager 对整页内容执行有序 crop 重建，避免缩放或滚动期间残留旧
   transform 像素。
6. 主画布与 crop render context 的 `save()/restore()` 使用 `finally` 对称收尾；渲染异常不能泄漏 Canvas 状态。
7. full-page durable compatibility rendering 也通过同一 `transientTopStroke` 物化规则，避免两条路径再次出现层级
   分歧。

## 结果

- 常见 Stroke→Text 与复杂 mixed z-order 页面遵守同一原版层级语义。
- Text/Image/Math 在 preview 下方时会像原版一样暂时被纸色 tool-5 Ink 覆盖。
- 每次 Move 仍只传输 growing dirty crop，不固定生成整页 preview bitmap。
- preview 仍然完全非持久；durable partial erase 继续只保存普通 Ink/Shape remnants 与 source deletion。

## 代价与后续

dirty crop 会遍历并重绘所有相交前景类型，CPU 成本高于 handwriting-only 缓存，但比整页 transfer 更可控，且
正确性优先。后续真机数据若显示复杂页面仍有压力，可按原版 tile renderer 引入可复用内容 tile cache；不得以
恢复 Text 固定前景的方式换取性能。
