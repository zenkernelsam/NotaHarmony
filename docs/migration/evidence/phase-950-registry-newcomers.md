# Phase 950 证据 — 注册表新五类型实名

## `p9` = `AcknowledgeAppendedOpsEvent`（实证）

`{acks:List}` —— 服务器→客户端批量 ack
事件（lv2.s 物化）。信封层。

## `q89` = `NoteMutationResponse`（实证）

`{noteId:utf@l(), acks:List@lv2.t}` ——
note 变更响应：UUID + ack 表。

## `xq3` = `DuplicateOp`（xwd 24B inline，实证）

| 访问器 | 偏移 | 字段 |
|---|---|---|
| `d()` | this.I+0 | opId:qo5 |
| `e()` | this.I+8 | originalServerTime:long |
| `c()` | this.I+16 | duplicateServerTime:long |

**sg5 DUPLICATE_OP_HOLDER 实例确认**——
重复 op 去重记录（原/复双服务器时间）。

## `r60`/`yq3` = 抽象 cee 基类

`abstract extends cee implements ka4`——
密封基类（无 extends 命中=生成子类或
泛型擦除）；yq3 有注册写器 `qee(7)`。

## 结论

五新类型实名：双 ack 事件/响应 +
DuplicateOp 24B + 双抽象基。
