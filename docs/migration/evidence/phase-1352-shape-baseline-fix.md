# Phase 1352 证据 — 形状检测基线归属更正

**更正 Phase 1327**：`b90.java` 实为 `AbstractSet` 子类
（collection wrapper），非形状检测器。真实原版基线为
`*5d`/`uf8`/`h8d`/`mih` 族。

## 真实原版形状检测基线

```
g5d = ShapeDetectorOutput{confidence, offset, shape}
  // toString: "ShapeDetectorOutput(confidence=…, offset=…,
  //   shape=…)"
uf8 implements xf8 —— 检测器接口实现（xf8 = detector 接口）
f5d —— 点聚类（mih.c((h8d),(h8d)) < 0.05f 簇容差，
  h8d = {double a,b} 2D 点，ArrayList 累积）
h5d —— ShapeDetectorOutput 相关记录（hashCode 字段）
mih —— 抽象数学/距离 helper
```

→ 原版形状检测 = `uf8`(detector)→`g5d`(输出
confidence+offset+shape)+`f5d`（0.05f 点聚类）+
`h8d`(点)+`mih`(几何距离) —— 真实基线族。

## 更正说明

Phase 1327 引用 `b90`/`b16` 为误标（`b90`=AbstractSet）。
Harmony `ShapeDetector`（hold-to-detect + 置信度+0.6/60/
120 阈值+DouglasPeucker）语义与真实基线 `g5d`(confidence
输出)+`f5d`(聚类) **结构对齐**，但原版精确常量未逐字
恢复 —— Harmony 0.6/60/120 为文档化近似。

## Harmony 决策

形状检测对照真实 `g5d`/`uf8`/`f5d`/`mih` 基线；阈值
常量为文档化近似（原值未在可读字段暴露）。

## 产出

- fixture `d02-shape-baseline-fix.mjs`（10 断言）。
- ADR-1293；中文报告。
