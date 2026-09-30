# Phase 1327 证据 — `ShapeDetector` 形状识别审计

来源：`core/algorithm/ShapeDetector.ets` vs 原版 `b16.h`/
`e5d`/`b90`。

## `ShapeDetector implements RecognitionProvider` =
hold-to-detect 形状识别（hold 计时器触发）

```
输出 kind：0=LINE(开折线也归此)/1=ELLIPSE/2=POLYGON(闭合)
lineThreshold=0.6     直线判据：距离/跨度 > 0.6
lineMinLength=60px    直线最小长度
ellipseMaxGap=120px   椭圆首尾最大距离
b16.h()  多边形"最短边<最长边 1/4"=uneven 覆盖门
         （开折线判 LINE）
e5d      仲裁元数据（候选 kind+polygon/ellipse 限定）
```

## 语义

形状识别 = **长按触发**的几何分类（线/椭圆/多边形）+
原版阈值（0.6/60/120px）+ uneven 覆盖门+`e5d` 仲裁 ——
对照原版保真。

## Harmony 决策

`ShapeDetector` 实现 `RecognitionProvider` 抽象（可插拔）
—— 原版阈值/分类/仲裁保真移植。

## 产出

- fixture `d02-shape-detector.mjs`（10 断言）。
- ADR-1271；中文报告。
