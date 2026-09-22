# ADR-0551: Tape 元素恒置顶渲染序（vnd.compareTo 对齐）

## Status

Accepted, 2026-09-28.

## Context

原版元素排序比较器 `vnd.compareTo`（decompiled_1.0.3）在比较
zIndex/ID 之前先比较 `ly3.k()`（isTape）：仅一侧为 tape 时 tape
排最后——**tape 元素恒渲染于所有非 tape 元素之上**，z-order 操作
无法把内容盖到胶带之上（study tape 语义要求胶带遮盖下层内容）。
tape 元素之间仍按常规 (zIndex, id) 排序。

Harmony 此前 `materializePageElements` 严格按持久化 zIndex 物化，
不含 tape 特权——若用户把图片/笔迹置顶到 tape 之上，遮盖语义即破。

## Decision

- `materializePageElements` 物化后对结果做稳定分区：tape 元素
  （笔画 `renderSpec.tapePattern` 非空；形状 `originalTool === 3`）
  移至末尾且保持相对顺序。
- transient 进行中笔画仍追加在最后（对应原版在制笔迹覆盖层）。
- 不引入独立 tape 层或额外字段——复用既有 tapePattern/originalTool
  标记，与 op 编解码一致。

## Consequences

- tape 遮盖语义与原版一致：任何元素无法通过 z-order 盖到 tape 上。
- 回放 `d02-original-tape-zorder.mjs` 钉死分区规则与两种标记。
- REVIEW 工具创建链路、pattern picker、hide/reveal 开关为后续阶段；
  本 ADR 只闭合渲染序规则。
