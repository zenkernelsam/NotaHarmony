# Phase 916 证据 — 文本样式 op 四表（pub/me8/he8/io1）

## 目的

文本样式 op 族实名（zq9 type7-14 注册族收尾）。

## `pub` = `RemoveChar`（单数变体）

`{location:cxc@0(c4), textField:qo5@1(c6)}` ——
`REMOVE_CHAR`；与 qub RemoveChars（cxc[] 向量）配对。

## `me8` = `ModifyStyle`（15 槽）

`ModifyStyle(start=, end=, textField=, bold=, italic=,
underline=, highlight=, familyName=, size=,
foregroundColor=, link=, superscript=, subscript=,
strikethrough=, code=)`

| 字段 | c(N) | 类型 | 语义 |
|------|------|------|------|
| s() | c(4) | `v01` | start |
| l() | c(6) | `v01` | end |
| w() | c(8) | `qo5` | textField |
| j() | c(10) | `z1d` | bold |
| p() | c(12) | `z1d` | italic |
| x() | c(14) | `z1d` | underline |
| o() | c(16) | `g2d` | highlight |
| m() | c(18) | `z2d` | familyName |
| r() | c(20) | `k2d` | size |
| n() | c(22) | `g2d` | foregroundColor |
| q() | c(24) | `z2d` | link |
| v() | c(26) | `z1d` | superscript |
| u() | c(28) | `z1d` | subscript |
| t() | c(30) | `z1d` | strikethrough |
| k() | c(32) | `z1d` | code |

**全部样式属性 setter 包装**——字符样式族为
`v01`(范围)×2 + `qo5` + `z1d`SetBool×7 + `g2d`SetColor×2
+ `z2d`SetString×2 + `k2d`SetFloat。

## `he8` = `ModifyParagraphStyle`（10 槽）

`ModifyParagraphStyle(start=, end=, indentLevel=,
alignment=, lineSpacing=, decoratorStyle=, isChecked=,
textField=, programmingLanguage=, writingDirection=)`

| 访问器 | c(N) | 类型 | 语义 |
|--------|------|------|------|
| p() | c(4) | `cxc` | start |
| l() | c(6) | `cxc` | end |
| n() | c(8) | `k2d` | lineSpacing |
| j() | c(10) | `o2d` | alignment（枚举 setter） |
| m() | c(12) | `a3d` | indentLevel |
| s() | c(16) | Boolean | isChecked |
| q() | c(18) | `qo5` | textField |
| o() | c(20) | `z2d` | programmingLanguage |
| r() | c(22) | `b3d` | writingDirection |
| k() | c(14) | `j2d` | decoratorStyle |

新 setter 类型：`o2d`(alignment)、`j2d`(decoratorStyle)、
`a3d`(indentLevel)、`b3d`(writingDirection)——枚举 setter
族扩展。注意 start/end 为裸 cxc（段落样式不带 v01
setter 包装，与字符样式不同）。

## `io1` = `ClearStyle`

`{start:cxc, end:cxc, paragraph:bool, textField:qo5}`
—— 4 字段，清除范围样式。

## 结论

文本 op 族全闭：字符增删 5 表 + 样式 3 表 +
段落样式；setter 包装通则全域确认（字符样式 setter，
段落样式裸 cxc 边界+枚举 setter）。
