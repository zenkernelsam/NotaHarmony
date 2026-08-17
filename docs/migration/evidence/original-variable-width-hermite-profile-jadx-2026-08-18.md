# 原版可变宽度单调 Hermite 属性曲线证据（2026-08-18）

## 1. 基准与哈希

原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage`

| 文件 | SHA-256 | 本阶段用途 |
|---|---|---|
| `z8a.java` | `CAC75274BE9E34034DDD8A27171F98C89213D71C329597DAFCCFFDF0C9733AB8` | attributed path 宽度 profile、误差判据与曲线切分 |
| `jqi.java` | `A2B2E9B36A3CF77071A485EACA498709CB7A3A994CAAC15A648A5E255966F8A9` | 三个探针与 cubic Hermite 基函数 |
| `fa2.java` | `D2E0BA216B3664A4357054171B780D781F990D29534457D5C6705B2969CE7692` | 加权调和导数分母的合成项 |
| `ed0.java` | `DA1D4747487E248BB0DC235DE0A19CD00C1FDE1AE8404FE869FD7398D38EC32D` | `cd0.e()` 确认为 `strokeWidth` 属性 |

`z8a` 的类常量描述中直接出现
`bezierkit/extensions/AttributedPathComponentIterator$DetermineInternalArcResult`，说明本段位于原版 bezierkit
attributed-path/outline 链，而不是 UI 层的视觉补丁。本证据只还原宽度属性预处理；同一大方法后续 offset/internal-arc
与最终 Path 行为不在本阶段完整移植范围。

## 2. 触发边界：多组件、完整属性、宽度确实变化

`z8a.java:422-451` 只处理 `fd0` attributed path，并要求：

- `sj8Var4.b >= 2`，即至少两个 path component；
- 属性列表 `r7.o` 的数量严格等于 `componentCount + 1`；
- 从第二个属性开始检查 `cd0.e()`，只有任一 stroke width 不同于首值才进入细化。

因此常量宽度与单组件不是“用相同算法算出 1 段”，而是根本不重建 attributed path。Harmony 内部以 subdivision=1
表达同一个“不额外做宽度切分”的结果。

`ed0.java:13-18,41-43,61-68` 证明构造器第一个字段 `I` 由 `e()` 返回，`toString()` 将其命名为
`strokeWidth`。Harmony 的 `StrokePathPoint.widthFactor` 是同一类逐点宽度因子，最终才由
`WidthOutlineBuilder.halfWidth()` 乘 `baseWidth / 2`，因此 profile 应作用于 factor，而不是先乘画笔基宽。

## 3. 弦长、割线与单调导数

### 3.1 每组件弦长至少为 `1e-6`

`z8a.java:452-497` 按每个 path component 的阶数推进控制点游标，并计算组件首末点距离；`:489-493` 明确把小于
`1.0E-6` 的距离钳制为 `1.0E-6`。这不是 bezier 弧长，而是组件端点弦长。

### 3.2 每组件宽度割线斜率

`z8a.java:500-510` 先把全部 `cd0.e()` 放入宽度数组，再计算：

```text
slope[i] = (width[i + 1] - width[i]) / chordLength[i]
```

### 3.3 端点导数与内部符号门

`z8a.java:511-525`：

- 首导数等于首割线斜率；
- 末导数等于末割线斜率；
- 相邻割线斜率乘积 `<= 0` 时，内部导数为 0；
- 同号时使用弦长加权调和导数。

结合 `fa2.java:71-73`，原版内部导数可写为：

```text
d[i] = 3 * (hPrev + hNext) /
       (((2*hPrev + hNext) / slopeNext) +
        ((2*hNext + hPrev) / slopePrev))
```

这是 shape-preserving/PCHIP 型导数：斜率换号处压成水平切线，同号处使用加权调和均值，避免普通 cubic 插值在宽度
峰谷附近产生过冲。

## 4. Hermite 基函数与自适应组件数

`jqi.java:12` 固定探针为 `{0.25, 0.5, 0.75}`。`jqi.java:409-413` 的六参数函数把当前组件的起止宽度、
起止导数、组件弦长和参数 `t` 组合为 cubic Hermite：

```text
w(t) = (t^3 - t^2)       * dEnd   * h
     + (-2t^3 + 3t^2)    * wEnd
     + (t^3 - 2t^2 + t)  * dStart * h
     + (2t^3 - 3t^2 + 1) * wStart
```

`z8a.java:567-595` 对三个探针比较 Hermite 与端点线性宽度：

```text
scaledDeviation = maxProbeError * 1.2
tolerance = max(startWidth, endWidth, 0.05) * 0.005
```

- `abs(scaledDeviation) > Double.MAX_VALUE`（溢出）或偏差不超过容差时不重建该组件；
- 否则组件数为 `clamp(ceil(sqrt(scaledDeviation / tolerance)), 2, 6)`。

因此 `2～6` 不是几何曲率细分上限，而是独立的宽度属性误差门。Harmony 随后仍可在每个属性子组件内部执行既有
cubic 几何展平，两层职责不能混淆。

## 5. 等参数切曲线与插入属性

`z8a.java:631-695` 对需要细化的源组件循环：

- `startT = partIndex / partCount`；
- `endT = (partIndex + 1) / partCount`；
- line/quad/cubic 分别按 `[startT,endT]` 取得原曲线子段；
- 非末尾边界的 stroke width 使用 `jqi.d(...)` 计算；
- force、altitude、azimuth X/Y 仍按端点线性插值；
- 最后一段直接复用原终点属性对象，避免数值重建改变最终锚点。

Harmony 的 `sliceCubic()` 使用 De Casteljau 先取 `[0,endT]`，再从该段取 `[startT/endT,1]`，得到同一原参数区间；
每个插入边界写入 Hermite width。既有 `flattenCubic()` 只在该新子组件内部线性传递端点属性，对应原版插入边界后
由下游 consumer 消费 attributed components 的行为。

有效持久化输入应使上述数值保持有限。原版显式跳过大于 `Double.MAX_VALUE` 的溢出；Harmony 额外把任何派生的
非有限偏差都降为“不额外做宽度切分”，防止损坏数据继续产生 NaN 轮廓。这是 fail-safe 扩展，不冒充原版分支。

## 6. 独立数值重放

取宽度 `[1,3,2]`、两段弦长 `[10,10]`：

- 割线斜率为 `[0.2,-0.1]`；
- 中间斜率换号，导数为 `[0.2,0,-0.1]`；
- 第一段三个探针最大线性偏差为 `0.28125`，乘 `1.2` 后为 `0.3375`，容差 `0.015`，得到 5 段；
- 第二段最大偏差为 `0.140625`，乘 `1.2` 后为 `0.16875`，容差 `0.015`，得到 4 段；
- 第一段 `t=0.4` 的 Hermite 宽度为 `1.992`，旧线性值仅 `1.8`；
- 第二段 `t=0.5` 的 Hermite 宽度为 `2.625`，旧线性值为 `2.5`；
- 101 个均匀参数点均落在各自相邻端点极值内。

同号例 `[1,2,6]`、弦长 `[10,20]` 的内部导数为 `0.12857142857142856`，锁定加权调和公式而不是简单平均。

## 7. Harmony 实现映射与边界

`note/src/main/ets/core/algorithm/WidthOutlineBuilder.ets` 现：

- 从拟合 cubic 与持久化 path point 建立连续宽度锚点；
- 恢复原版弦长、割线、单调导数、Hermite evaluator 与误差细分公式；
- 只在需要时切 cubic，常量宽度、单组件和损坏 cubic 保留既有 fallback；
- 实时 `StrokeSession`、持久化 renderer 与局部擦除仍通过共享 builder 消费相同逻辑。

`docs/migration/replays/d02-original-variable-width-hermite-profile.mjs` 同时检查原版源码片段、独立数值模型、Harmony
生产接线与 ArkTS fixture。它不能证明最终 offset polygon 与原版 bezierkit 的 internal arc、布尔消交或像素完全一致；
这些边界继续由 `ADR-0002`、M2-A-09 与 M2-R-13 管理。
