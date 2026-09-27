# Phase 917 证据 — ge8/s83/je8/tdf 四表

## 目的

页面修改/实体删除/批量位移/瞬态结束 op 实名。

## `ge8` = `ModifyPage`（toString 实证）

`ModifyPage(pages=, moveTo=, background=, bookmarked=)`

| 访问器 | c(N) | 类型 | 语义 |
|--------|------|------|------|
| `n(i,cxc)`/`m()` | c(4) | `cxc[]` 12B 向量 | **pages** 目标集 |
| `l()` | c(6) | `lxc` | **moveTo**（SeqMove） |
| `j()` | c(8) | `m2d` | **background**（SetPageBackground setter） |
| `k()` | c(10) | `oz9` | **bookmarked**（865 枚举） |

`haa.MODIFY_PAGE`；单 op 混合页面移动+背景+书签。

## `s83` = `DeleteEntities`（toString 实证）

`DeleteEntities(entityDeletes=, entityUndeletes=,
pageDeletes=, pageUndeletes=)`

| 访问器 | c(N) | 类型 | 语义 |
|--------|------|------|------|
| `j(qo5,i)`/`l()` | c(4) | `qo5[]` | entityDeletes |
| `k(qo5,i)`/`m()` | c(6) | `qo5[]` | entityUndeletes |
| `p(i,cxc)`/`n()` | c(8) | `cxc[]` | pageDeletes |
| `q(i,cxc)`/`o()` | c(10) | `cxc[]` | pageUndeletes |

`haa.DELETE_ENTITIES`；**双墓碑对**：实体 qo5[] +
页面 cxc[]，各带删除/复活向量——软删除协议
（undo/同步重放可逆）。

## `je8` = `ModifyPositions`

`{modifications:ie8[]@0(c4)}` —— 899 ie8
ModifyPosition 表向量，`haa.MODIFY_POSITIONS`。

## `tdf` = `TransientInteractionEnded`

`{interactionId:qo5@0(c4 必填), replacedByOp:qo5@1(c6)}`
—— 瞬态交互收尾标记；sdf 建立（907）→tdf 终结。

## Harmony 核对

ModifyPage 四字段编码对齐；DeleteEntities 双墓碑
向量对为同步可逆语义；tdf 必填 interactionId。

## 结论

zq9 注册表再闭 4 表；瞬态生命周期 sdf↔tdf 成对。
