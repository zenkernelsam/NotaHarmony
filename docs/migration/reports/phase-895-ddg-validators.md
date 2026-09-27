# Phase 895 报告 — `ddg` 校验助手全集实名

## 范围

补全 ddg 共享校验静态类；ka4 实现面扩展。纯审计。

## 原版发现

- `ddg` 助手：a=ε1e-4 比较、d=有限性、l=标签包装、
  i=尺寸≥0、j=缩放、k=ka4 委托、h=点、e=文本修改
  （位置+旋转+缩放）、m=centerPath/styleMap、
  b/c/n/o=路径·长整·迭代·点对。
- ka4 实现者扩展实证：qed/vy7/fqa。
- 统一 ε=1e-4 与 `"label: err"` 层级消息。

## Harmony 核对

throw 门 + 数值守卫对齐 ε/有限性/层级格式；
centerPath-styleMap 一致性对齐。

## 产出

- 证据：`phase-895-ddg-validators.md`
- Fixture：`d02-ddg-validators.mjs`（15/15）
- ADR-0839；全量 Replay 768 文件绿。
