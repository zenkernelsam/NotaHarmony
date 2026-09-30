# ADR-1256：文档模型覆盖

## 状态

已接受（Phase 1312）。

## 决策

Harmony `core/model` 全实现文档模型（元素/页面/形状
识别/原版策略）—— 模型语义保真。

## 理由

31 文件：元素块（image/math/text/shape/stroke/brush）、
页面（background/coordinate/order/paper/template）、
`Original*` 策略（snap/crop/insertPlan/title/metadata/
language）、形状识别（recognition/hold）、`OpTypes`
—— 数据模型层完备+原版保真移植。

## 后果

Harmony 文档模型与原版元素/页面/策略语义一致 —
— 模型保真。
