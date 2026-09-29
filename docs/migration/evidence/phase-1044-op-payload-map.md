# Phase 1044 证据 — 操作载荷类全集 + ka4=校验接口

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `z5c` op→payload 分派表（`uq9.m().ordinal()` switch）

| haa | 操作 | 载荷类 |
|---|---|---|
| 0 | NONE | `throw null`（fail-loud） |
| 1 | SET_METADATA | `l2d` |
| 2 | ASSET_CLOUD_PERSISTED | `ra0` |
| 3 | CREATE_PAGE | `ln2` |
| 4 | MODIFY_PAGE | `ge8` |
| 5 | CREATE_RECORDING | `yn2` |
| 6 | MODIFY_RECORDING | `ke8` |
| 7 | INSERT_CHAR | `e46` |
| 8 | INSERT_STRING | `f46` |
| 9 | REMOVE_CHAR | `pub` |
| 10 | REMOVE_CHARS | `qub` |
| 11 | REVIVE_CHARS | `f2c` |
| 12 | MODIFY_STYLE | `me8` |
| 13 | MODIFY_PARAGRAPH_STYLE | `he8` |
| 14 | CLEAR_STYLE | `io1` |
| 15 | CREATE_INK | `dm2` |
| 16 | ADD_PATH_ELEMENTS | `gd` |
| 17 | MODIFY_INK | `wd8` |
| 18 | CREATE_SHAPE | `ao2` |
| 19 | MODIFY_SHAPE | `le8` |
| 20 | CREATE_GROUP | `cm2` |
| 21 | MODIFY_GROUP | `vd8` |
| 22 | CREATE_BLOCK | `rl2` |
| 23 | MODIFY_BLOCK | `td8` |
| 24 | MODIFY_POSITIONS | `je8` |
| 25 | DELETE_ENTITIES | `s83` |
| 26 | TRANSIENT_INTERACTION_ENDED | `tdf` |
| 27 | MODIFY_PDF_FIELD | `ee8` |
| 28 | UPDATE_CHECKBOX | `mqf` |
| 29 | PEER_INTERACTION | `yda` |
| 30 | CREATE_COMMENT | `tl2` |
| 31 | MODIFY_COMMENT | `ud8` |
| default | — | `return null` |

所有载荷 `extends cee implements ka4`（Table+校验）。

## `ka4` = 校验接口（修正此前"String 访问器"解读）

`ka4.a()` 返回**校验失败原因字符串**，null=通过。

## `l2d`（SET_METADATA）校验规则（`a()` 实测）

- title（`z2d.j()`）：非空且 ≤256 字符。
- `m2d.j()→nz9` 经 `ddg.g` 校验（子字段错误透传）。
- 模板 PDF：`sw9.o() != 1` → "Template PDFs can only
  consume (have) one page"。
- 默认字号 `m()`：必须 >0。
- 默认字体族 `l()`：≤30 字符。

## HarmonyOS 决策

- 32 载荷类逐一映射；`ka4.a()` 建模为
  `validate(): string | null`。
- SET_METADATA 校验规则逐条保留（256/30/>0/模板单页）。

## 产出

- fixture `d02-op-payload-map.mjs`（12 断言）。
- ADR-0988；中文报告。
