# ADR-1056：序列树节点 + 长键 map + 文本 spec

## 状态

已接受（Phase 1112）。

## 决策

- `f8d` = 序列节点 `{site,seq,pos,qwc nav,List,int}`，`a(hr5,i)` 锚访问。
- `g8d` = 抽象 long→f8d map；`y51` 适配 wia。
- `bxc` = 文本 spec `{sia, 2×hja, k5c,z4,kia,cl2}`。

## 依据

bxc→iwc→y51→f8d→hr5 全栈链路。

## 后果

Harmony 文本序列 = spec/live + 树节点 + 长键索引；双持久
map ↔ 双 builder 结构保留。
