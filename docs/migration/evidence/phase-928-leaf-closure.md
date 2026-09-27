# Phase 928 证据 — 叶结构闭合 + zgb/ww9

## 目的

剩余叶结构与线型尾表实名。

## 叶结构布局钉死

| 类 | 名称 | 布局 |
|----|------|------|
| `fqa` | `Point` | `{x:float@0, y:float@4}` 8B |
| `qed` | `Size` | `{width:float@0, height:float@4}` 8B（自然序） |
| `hd1` | `CanvasAnchor` | `{page, origin}` 结构 |
| `hu1` | `Color` | `{r,g,b,a}` 4B（892） |
| `cxc` | 位置 ID | `{site:u16,pad,ts:u32,idx:u32}` 12B（880） |
| `qo5` | op/实体 ID | `{site:u16,pad,ts:u32}` 8B（887） |
| `utf` | UUID | 16B |
| `ua0` | SHA-512 | 64B |

## `my3` = `EntityAnchor{entities:qo5[]}`

实体集锚点（评论 anchor 的实体型分支——
`z5c.t` 多态候选）。

## `zgb` = `ReceiveOpsEvent`

`{ops:uq9[], expectedAckReply:String,
schemaVersion:ymf}` —— **服务端→客户端 op 批量
下发事件**（同步协议收包侧）。

## `ww9` = `{STRING=0, BOOLEAN=1}`

ModifyPDFField 的 `valueType` 枚举——PDF 表单值
类型判别（string/bool 双表示之别名）。

## Harmony 核对

Point/Size 自然序字段对齐；ReceiveOpsEvent 对应
同步收包模型；PDF 值型枚举对齐。

## 结论

线层叶结构全部实名——点/尺寸/颜色/位置/ID/UUID/
哈希布局与锚点型别全集。
