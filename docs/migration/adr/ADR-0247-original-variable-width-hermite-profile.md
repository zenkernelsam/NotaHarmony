# ADR-0247：原版可变宽度单调 Hermite 属性曲线

## 状态

Accepted - Phase 269（2026-08-18）

## 背景

`ADR-0002-variable-width-outline.md` 已决定：Harmony 使用拟合 cubic 的自适应几何展平、圆弧外接头与受限内交点，
作为原版 bezierkit offset/internal-arc 的显式近似。该阶段虽然让实时 bounds 与持久化重绘共享同一 cubic，却仍在每个
cubic 的起止宽度之间做线性插值。

重新直读原版 1.0.3 `z8a/jqi/fa2/ed0` 后确认，原版在真正生成轮廓前还有一层独立的 attributed-path
宽度细化：按组件端点弦长建立单调 cubic Hermite 曲线，并依据 Hermite 相对线性宽度的偏差，把每个源曲线组件切成
0 或 2～6 个等参数子组件。旧 Harmony 因缺少这一层，会把局部压力峰值和相邻变化率线性抹平；几何中心线虽相同，
轮廓半径沿曲线的变化仍与原版不同。

完整原版证据见
`docs/migration/evidence/original-variable-width-hermite-profile-jadx-2026-08-18.md`。

## 决策

### 在现有几何近似前恢复原版宽度属性预处理

- 仅当至少有两个 cubic、属性锚点数量匹配且宽度确实变化时建立 profile；单组件或常量宽度继续走原路径。
- 每个组件长度取 cubic `p0→p3` 的弦长，并按原版钳制到至少 `1e-6`。
- 每组件割线斜率为相邻宽度差除以弦长；首尾导数分别等于首尾割线斜率。
- 内部相邻斜率乘积 `<= 0` 时导数归零，避免跨越局部极值；同号时使用原版弦长加权调和导数。
- Hermite 基函数与原版 `jqi.d()` 相同，端点导数均乘当前组件弦长。

### 使用原版误差探针决定属性子组件数

- 在 `t=0.25/0.5/0.75` 比较 Hermite 宽度与线性宽度，取最大绝对偏差。
- 偏差乘 `1.2`；容差为 `max(startWidth,endWidth,0.05) * 0.005`。
- 偏差不超过容差时不额外切分；否则使用
  `clamp(ceil(sqrt(deviation/tolerance)), 2, 6)`。
- 需要切分时，以 De Casteljau 在等参数区间切原 cubic，并在每个插入边界写入 Hermite 宽度。

### 保留明确的平台边界

原版在插入边界后由 attributed path 持有新属性。Harmony 没有同一 bezierkit 类型，因此先把每个 cubic 切成对应
子组件，再让既有几何展平在子组件两个属性锚点之间线性插值；这与原版“先插边界、再由后续 consumer 消费组件属性”
的可观察结果一致。

本 ADR 只替换宽度属性曲线。`ADR-0002` 中的最终 offset、inside miter、圆弧 join、self-intersection 与 Path
布尔轮廓仍是 Harmony 近似，不能因本阶段被描述成完整 bezierkit 等价。

## 后果

- 变宽 Ink 的局部峰值、谷值及相邻斜率变化不再被整段线性宽度抹平。
- 相邻斜率异号时内部导数归零，Hermite 曲线不会越过相邻端点极值。
- 原版 `1e-6`、三个探针、`1.2`、`0.005` 与 2～6 clamp 成为可重放常量，不再使用移植侧猜测。
- cubic 几何仍来自持久化已有字段，不改变 `StrokeElementData`、数据库或包格式。
- 常量宽度、单组件及损坏 cubic 的既有防御性 fallback 保持；不会仅因存在 cubic 列表而制造额外宽度切分。
- M2-A-09/A-21 不整体关闭；设备像素、选区缩放笔宽和完整 offset/internal-arc/布尔轮廓继续开放。

## 验证契约

- 数值例 `[1,3,2]`、弦长 `[10,10]` 必须得到导数 `[0.2,0,-0.1]`、细分数 `[5,4]`、
  第一段 `t=0.4 → 1.992`、第二段 `t=0.5 → 2.625`。
- ArkTS fixture 必须覆盖上述两个轮廓半径、局部极值不越界及常量宽度不额外细分。
- 桌面 Replay 必须同时锁定原版源码片段、独立数值模型、生产接线和 fixture 注册。
- `note@ohosTest` 只证明 fixture 通过 ArkTS 编译/打包，不冒充设备执行 Hypium assertions。

## 未决项

- 原版 bezierkit offset/internal-arc、局部自交消解和最终 Path 布尔轮廓的完整等价实现；
- 0.5×/2× 选区缩放后的笔宽语义（M2-R-13）；
- 原版/Harmony 像素对照、急转弯与压力峰值设备观感、真实擦除命中和性能。
