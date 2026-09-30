# ADR-1219：CRDT 操作分类法

## 状态

已接受（Phase 1275）。

## 决策

`haa` 32-op 枚举 + `tmf` Lamport 时间戳 + `sdf` 实体
→ Harmony `enum OpType`+逻辑时钟。

## 理由

`haa` = 完整笔记文档 CRDT op 词汇（协同文本 insert/
remove/revive 墓碑、样式、墨迹、图形、分组、块、PDF
域、复选框、评论、协同存在）；`tmf`=可排序 long
时间戳；`sdf`=`qo5`+`mmf` 实体 —— 协同文档模型。

## 后果

Harmony 文档 op = enum OpType（32 值）+逻辑时钟 —
— CRDT 词汇完整保真。
