# Phase 1275 证据 — haa 32-op CRDT 分类法 + tmf 时间戳

来源：`defpackage/{haa,tmf,sdf,mmf,xwd}.java`。

## `haa` = 完整 CRDT 操作类型枚举（32 值）

```
NONE(0) SET_METADATA(1) ASSET_CLOUD_PERSISTED(2)
CREATE_PAGE(3) MODIFY_PAGE(4)
CREATE_RECORDING(5) MODIFY_RECORDING(6)
INSERT_CHAR(7) INSERT_STRING(8) REMOVE_CHAR(9)
REMOVE_CHARS(10) REVIVE_CHARS(11)          ← 协同文本（revive=墓碑复活）
MODIFY_STYLE(12) MODIFY_PARAGRAPH_STYLE(13) CLEAR_STYLE(14)
CREATE_INK(15) ADD_PATH_ELEMENTS(16) MODIFY_INK(17)
CREATE_SHAPE(18) MODIFY_SHAPE(19)
CREATE_GROUP(20) MODIFY_GROUP(21)
CREATE_BLOCK(22) MODIFY_BLOCK(23) MODIFY_POSITIONS(24)
DELETE_ENTITIES(25) TRANSIENT_INTERACTION_ENDED(26)
MODIFY_PDF_FIELD(27) UPDATE_CHECKBOX(28) PEER_INTERACTION(29)
CREATE_COMMENT(30) MODIFY_COMMENT(31)
```

## `tmf` = 逻辑时间戳 value-class

`{long I}` `Comparable` + `toString=njj.j0(10,I)` —
— CRDT Lamport/HLC 逻辑时钟（排序 op）。

## `sdf` = 实体记录表

`extends cee implements ka4` — `{qo5 j() entity-id,
mmf k()}` —— 实体=id+payload。

## `xwd` = FlatBuffers Struct 基类

`{int I, ByteBuffer J}` + `b(i,bb)` —— 内联小记录。

## `mmf` = 实体 payload 类型。

## 语义

**完整笔记文档 CRDT 操作词汇** —— 协同文本（insert/
remove/revive 墓碑）、样式、墨迹、图形、分组、块布局、
PDF 表单域、复选框、评论、协同存在 —— 一个可协同
编辑的富文档模型的全部 op 类型。

## Harmony 决策

32-op 枚举 + Lamport 时间戳 → Harmony `enum OpType`+
逻辑时钟 —— CRDT op 词汇完整保真。

## 产出

- fixture `d02-op-taxonomy.mjs`（10 断言）。
- ADR-1219；中文报告。
