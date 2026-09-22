# Phase 577 — 原版形状识别仲裁规则（e5d.b 双阈值覆盖）Harmony 对齐证据

日期：2026-09-22
基准：`decompiled_1.0.3/sources/defpackage/`
（`e5d.java`、`s16.java`、`b16.java`、`m06.java`、`gih.java`、`mih.java`、
`y90.java`、`cg7.java`）。

## 原版仲裁结构（e5d.b）

`e5d(f, list)` 构造 `f5d`，`b()` 在 4 个候选识别器上取最高置信度：

```java
listM0 = m18.m0(cg7Var, new y90(f, 1, list2), new y90(f, 3, list2),
                new y90(f, 0, list2));
// → 遍历各候选 .b()，收集 g5d(confidence, ?, r16)
// → argmax 得 g5dVar3
```

候选器职责（`y90.java` switch(this.b) / `cg7.java` / `jt3.java`）：

- `cg7`（extends `jt3`→`e5d` 组合器）= {`y90` mode 2, `v6b`} 的 argmax
  组合；`y90` mode 2 → `e()` → `t06("Shared Line Detector", …, s16.I)`
  = **LINE** 候选。`jt3.b()` 是纯 argmax，无覆盖规则——覆盖只存在于
  顶层 `e5d.b`。
- `y90` mode 1 → `d()` → `m06`（major/minor/rotation）= **ELLIPSE**。
- `y90` mode 3（default 分支）→ `b16` = **POLYGON**。
- `y90` mode 0 → `c()` 基于 `gih.a` 段间转角的角点分析——Harmony 无对应
  识别器（既有差距，记录）。

即原版评估序为 [LINE(或 v6b), ELLIPSE, POLYGON, corner]，Harmony 的
[line, ellipse, polygon] 与前三槽位一一对应，"首个 >0.3 候选"语义
在两侧同序成立。

`s16` 枚举（`s16.java` 静态块）：I=LINE(0)、J=ARROW(1)、SQUARE(2)、
RECTANGLE(3)、TRIANGLE(4)、K=POLYGON(5)、L=ELLIPSE(6)、M=BEZIERGON(7)。

随后两条覆盖规则（均先于最终 `f4 > 0.2f` 接受门）：

1. `best.a == K (POLYGON)` 且 `((b16) r16).h()`：
   - 覆盖①：按候选顺序找首个 `confidence > 0.3f` 的任意候选，命中则替换。
   - 覆盖②（在①之后再次判 `s16Var==K`，同条件）：按候选顺序找首个
     `confidence > 0.3f` 且 `type == L (ELLIPSE)` 且
     `((m06) r16).h == m06.i`（major==minor，即**正圆**）的候选，命中则替换。
2. `best.a == I (LINE)`：找首个 `confidence > 0.3f` 且 `type == ELLIPSE`
   的候选，命中则替换。

`b16.h()` 语义（b16.java:89-107）：`g()` 返回顶点段列表（`this.b`=闭合
标志——`y90` 构造 `new b16(list, ba6.o(first,last))`，闭合时在段列表
尾部追加首点回环）；对每段 `gih.g(y7d)` = `mih.c(a,b)` = **段长**
（`Math.hypot`）。取段长 min/max，`|min|/|max| < 0.25` 为真——即"边长
严重不均的 polygon"（手绘圆/曲线被误简化为多边形的典型特征）。

`m06` 为椭圆结果（toString 含 "major=","minor="），`h==i` 即长短轴相等
=正圆。

## 产品语义

- 弱胜出的 LINE 让位于尚可的 ELLIPSE（闭合曲线被误判成直线时纠回）。
- 边长不均的闭合 POLYGON（手绘团块）让位于更强的候选，优先纠回正圆。
- 覆盖门 0.3 高于接受门 0.2：覆盖只看"像样的替代者"。

## Harmony 移植（ShapeDetector.ets）

- `DetectionResult` 增加内部仲裁元数据：`kind`（0=LINE 1=ELLIPSE
  2=POLYGON，含开放 polyline）、`closed`、`circle`（归一化后 rx===ry，
  对应 m06.h==i）、`unevenEdges`（`hasUnevenEdges` 实现 b16.h：闭合环
  计入 last→first 边，开放链只算相邻边）。
- `recognizeShape` 改为先收集 candidates 数组（保持 line→ellipse→
  polygon 评估序作为"first candidate"序），argmax 后调用
  `applyOriginalOverride` 执行两条覆盖规则，再过 `> 0.2` 接受门。
- 常量：`ORIGINAL_SHAPE_OVERRIDE_CONFIDENCE = 0.3`、
  `ORIGINAL_POLYGON_UNEVEN_EDGE_RATIO = 0.25`。

## 已知不确定项（诚实记录）

- `y90` mode 0（`c()` 角点检测）与 `v6b` 无 Harmony 对应识别器——既有
  差距；其余槽位与 Harmony line/ellipse/polygon 同序对应（见上）。
- `b16.h()` 对闭合环是否因重复端点产生零长边（导致闭合即恒 uneven）在
  `mih.s`/`g()` 层存在解读空间；本实现采用去重顶点环的意图语义
  （等边 polygon→false；长短边悬殊→true）。
- ARROW/BEZIERGON/SQUARE/RECTANGLE/TRIANGLE 等原版类型在 Harmony 折叠为
  LINE/ELLIPSE/POLYGON（文件头既有声明）。

## Replay

`docs/migration/replays/d02-original-shape-override.mjs`（17 断言）：
阈值常量、仲裁接线顺序、两条覆盖规则、b16.h 边比门与回环处理、
m06 正圆标志、候选 kind 标注。
