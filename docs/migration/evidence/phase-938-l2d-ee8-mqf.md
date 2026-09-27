# Phase 938 证据 — `l2d`/`ee8`/`mqf` 字段级偏移

## `l2d` = `SetMetadata`（实证）

| 访问器 | 偏移 | 字段 | 类型 |
|---|---|---|---|
| `q()` | c(4) | title | z2d SetString |
| `p()` | c(6) | pageBackground | m2d SetPageBackground |
| `n()` | c(8) | handwritingLanguage | z2d SetString |
| `j()` | c(10) | alignTextToLines | Boolean |
| `l()` | c(12) | defaultFontFamily | String 裸值 |
| `m()` | c(14) | defaultFontSize | Float 裸值 |
| `o()` | c(16) | layoutMode | tv6 枚举 |
| `k()` | c(18) | blockWrapSupport | dz0 枚举 |

**8 字段精确镜像 a79 八个 LWW 寄存器**——
SetMetadata 即文档元数据批量写 op；前四项
setter-wrapped，后四项裸值。

## `ee8` = `ModifyPDFField`（实证）

| 访问器 | 偏移 | 字段 |
|---|---|---|
| `j()` | c(4) | assetHash:ua0 |
| `k()` | c(6) | key:String |
| `n()` | c(8) | valueType:ww9 |
| `m()` | c(10) | valueString:String |
| `l()` | c(12) | valueBoolean:Boolean |

## `mqf` = `UpdateCheckbox`（实证）

| 访问器 | 偏移 | 字段 |
|---|---|---|
| `k()` | c(4) | textField:qo5 |
| `j()` | c(6) | location:cxc |
| `l()` | c(8) | isChecked:bool |

## 结论

三 op 布局全钉死；SetMetadata↔a79 寄存器
镜像确认（9 号尾差：layoutMode/blockWrapSupport
裸枚举 vs a79 寄存器）。
