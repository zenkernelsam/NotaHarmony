# Phase 924 证据 — `haa` payload-type 枚举全集

## 目的

op 类型序数骨干实名——协议全 32 值钉死。

## `haa` 全集（枚举序实证）

| 值 | 名称 | 载荷类 |
|----|------|--------|
| 0 | NONE | —（未知回退） |
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

- 序数与 `zq9` 注册顺序逐行一致（同一 .dex 序）。
- `uq9.m()` 读法：byte→nz3 范围检查→NONE 回退；
  Harmony fail-closed 抛错为记录分歧（ADR-0850）。

## Harmony 核对

`OpTypes.ets`/`Original*Operation` 类型序数表对齐
32 值全集；UNKNOWN→NONE 语义分歧已记录。

## 结论

协议 op 类型骨干全 32 值实名——读侧枚举 +
载荷类映射双表闭合。
