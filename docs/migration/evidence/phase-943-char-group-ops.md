# Phase 943 证据 — 字符/组 op 偏移图

## 字符 op 五件套（实证）

| 表 | 布局 |
|---|---|
| `e46` InsertChar | `location:cxc@c(4), unicodeScalar:int@c(6), textField:qo5@c(8)` |
| `f46` InsertString | `location:cxc@c(4), string@c(6), textField:qo5@c(8)` |
| `pub` RemoveChar | `location:cxc@c(4), textField:qo5@c(6)` |
| `qub` RemoveChars | `locations:cxc[12B]@c(4), textField:qo5@c(6)` |
| `f2c` ReviveChars | `locations:cxc[]@c(4), textField:qo5@c(6)` |

**unicodeScalar 在 f46 与 e46 均 @c(6)**——
Insert 对共享 {location,content,textField}
三段式；Remove/Revive 对共享
{locations,textField}。

## 组 op 对（实证）

| 表 | 布局 |
|---|---|
| `cm2` CreateGroup | `members:qo5[]@c(4)` 单字段（0 成员校验拒绝） |
| `vd8` ModifyGroup | `group:qo5@c(4) 必需, members:qo5[]@c(6)` |

## 结论

字符五件+组对偏移全钉死——zq9 全注册表
读端偏移 100% 覆盖。
