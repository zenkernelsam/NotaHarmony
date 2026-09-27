# Phase 939 证据 — 尾批 op 表访问器→偏移钉死

## `s83` = `DeleteEntities`（实证）

| 字段 | 偏移 | 物化器 | 类型 |
|---|---|---|---|
| entityDeletes | c(4) | lv2.I | qo5[] |
| entityUndeletes | c(6) | lv2.J | qo5[] |
| pageDeletes | c(8) | lv2.W | cxc[] |
| pageUndeletes | c(10) | lv2.X | cxc[] |

**四墓碑向量**：实体（qo5）与页（cxc）各分
删除/恢复两向。

## `tdf` = `TransientInteractionEnded`（实证）

`{interactionId:qo5@c(4), replacedByOp:qo5@c(5)}`——
瞬态交互结束 + 取代它的持久 op 引用。

## `je8` = `ModifyPositions`（实证）

`{modifications:ie8[]@c(4)}` 单字段（lv2.S 物化）。

## `ge8` = `ModifyPage`（实证）

| 访问器 | 偏移 | 字段 |
|---|---|---|
| `m()`/`n()` | c(4) | pages:cxc[]（lv2.Y） |
| `l()` | c(6) | moveTo:lxc SeqMove |
| `j()` | c(8) | background:m2d SetPageBackground |
| `k()` | c(10) | bookmarked:oz9 |

## `tl2` = `CreateComment`（实证）

`{anchorKind:im@c(4), anchor@c(6), text@c(8)}`——
anchor 经 z5c.t 多态。

## `ud8` = `ModifyComment`（实证）

| 访问器 | 偏移 | 字段 |
|---|---|---|
| `k()` | c(4) | comment:qo5 |
| `j()` | c(6) | anchor:hd1 **仅 Canvas**（非多态！） |
| `m()` | c(8) | text:z2d SetString |
| `l()` | c(10) | resolved:z1d SetBool |

**关键差异**：CreateComment 锚多态（4 类型），
ModifyComment 锚字段固定 hd1——只能改
Canvas 锚位置，不能改锚类型。

## 结论

尾批六表偏移全钉死；s83 四墓碑语义 +
ud8 单锚型差异确认。
