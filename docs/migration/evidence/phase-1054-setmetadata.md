# Phase 1054 证据 — SET_METADATA 完整字段 + 包装枚举

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `l2d` SetMetadata（8 字段，toString 实名）

`{title:z2d, pageBackground:m2d, handwritingLanguage:z2d,
alignTextToLines:Boolean, defaultFontFamily:String,
defaultFontSize:Float, layoutMode:tv6→枚举,
blockWrapSupport:dz0→枚举}`

## 校验（`a()`，Phase 1044 已录，此补全）

title 非空≤256；`ddg.g(nz9)`；模板 PDF 单页；
字号>0；字体族≤30。

## 包装类型

| 类 | 语义 |
|---|---|
| `z2d` | **SetString{value}** —— 通用 set-string 字段（title/语言） |
| `m2d` | SetPageBackground{value:nz9}（Phase 1046） |
| `tv6` | layoutMode：PAGED=0 **PAGELESS=1** |
| `dz0` | blockWrapSupport：WRAP_ENABLED=0 /
  WRAP_DISABLED=1 / **LEGACY_WRAP_ENABLED=2** |

## 语义注记

- PAGELESS = 无限滚动笔记（Notability 新特性）。
- LEGACY_WRAP_ENABLED = 旧版环绕兼容档——迁移须保留
  三值（旧笔记可能携带 2）。
- alignTextToLines 为 Boolean（可空——三态：未设/开/关）。

## Harmony 决策

- 8 字段+校验保留；tv6/dz0 枚举 wire 对齐（含 LEGACY=2）。
- z2d/m2d 包装层建模为 `Set<T>` 联合字段。

## 产出

- fixture `d02-setmetadata.mjs`（11 断言）。
- ADR-0998；中文报告。
