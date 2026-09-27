# Phase 942 证据 — me8/he8/io1 样式 op 偏移图

## `me8` = `ModifyStyle`（15 字段，实证）

| 访问器 | 偏移 | 字段 | 类型 |
|---|---|---|---|
| `s()` | c(4) | start | v01 Boundary |
| `l()` | c(6) | end | v01 Boundary |
| `w()` | c(8) | textField | qo5 |
| `j()` | c(10) | bold | z1d |
| `p()` | c(12) | italic | z1d |
| `x()` | c(14) | underline | z1d |
| `o()` | c(16) | highlight | g2d SetColor |
| `m()` | c(18) | familyName | z2d |
| `r()` | c(20) | size | k2d SetFloat |
| `n()` | c(22) | foregroundColor | g2d |
| `q()` | c(24) | link | z2d |
| `v()` | c(26) | superscript | z1d |
| `u()` | c(28) | subscript | z1d |
| `t()` | c(30) | strikethrough | z1d |
| `k()` | c(32) | code | z1d |

## `he8` = `ModifyParagraphStyle`（10 字段）

| 访问器 | 偏移 | 字段 | 类型 |
|---|---|---|---|
| `p()` | c(4) | start | **cxc**（非 v01!） |
| `l()` | c(6) | end | cxc |
| `m()` | c(8) | indentLevel | a3d SetUInt8 |
| `j()` | c(10) | alignment | o2d |
| `n()` | c(12) | lineSpacing | k2d |
| `k()` | c(14) | decoratorStyle | j2d |
| `s()` | c(16) | isChecked | Boolean |
| `q()` | c(18) | textField | qo5 |
| `o()` | c(20) | programmingLanguage | z2d |
| `r()` | c(22) | writingDirection | b3d |

## `io1` = `ClearStyle`（4 字段）

`{start:v01@c(4), end:v01@c(6), paragraph:bool@c(8),
textField:qo5@c(10)}`

## 关键差异

**字符级样式用 v01 边界**（BEFORE/AFTER 语义），
**段落级样式用裸 cxc**（位置语义）——范围
表示不同层级。

## 结论

样式 op 三表全钉死；v01↔cxc 范围差异确认。
