# Phase 1353 报告 — 基线归属审计（更正）

## 完成内容

- 逐一复核 Phases 1325–1328 引用的原版混淆类名：
  `b90`=AbstractSet、`w4a`=synthetic when-map、`wy5`=
  ko3/DrawScope modifier、`gn3`=n73 节点基类 ——
  **4 处误标**；`ms1`=float 对、`dr4`=hr4 族正确；
  `sqh`=lm9 注册器（部分）；真实检测基线=`g5d`/
  `uf8`/`f5d`/`h8d`/`mih`。Harmony 实现语义正确不受影响，
  仅更正基线符号引用。

## 产出

- evidence `phase-1353-baseline-attribution.md`
- fixture `d02-baseline-attribution.mjs`（10/10）
- ADR-1294
