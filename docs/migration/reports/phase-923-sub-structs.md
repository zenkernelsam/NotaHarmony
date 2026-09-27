# Phase 923 报告 — 剩余子结构四枚实名

## 范围

载荷引用子结构收尾实名。纯审计。

## 原版发现

- ukb=RecordingSegment 16B；bmb=Rect{fqa+qed}；
  qqe=TextSelection{双 v01 Boundary}；
  yyd=StyleMap 20B 虚线渲染参数。
- 内联结构宽度谱系：8/12/16/20/64B 全实证。

## Harmony 核对

结构与宽度对齐。

## 产出

- 证据：`phase-923-sub-structs.md`
- Fixture：`d02-sub-structs.mjs`（12/12）
- ADR-0867；全量 Replay 796 文件绿。
