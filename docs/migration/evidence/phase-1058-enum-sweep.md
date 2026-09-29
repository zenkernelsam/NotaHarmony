# Phase 1058 证据 — 枚举清扫（11 个剩余枚举）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 枚举清单（byte 码）

| 类 | 值（语义） |
|---|---|
| `im` | 评论锚点：NONE=0 CANVAS_ANCHOR=1 TEXT_ANCHOR=2 ENTITY_ANCHOR=3 REPLY_ANCHOR=4 |
| `iq0` | **纸张色（稀疏码）**：CREAM=1 YELLOW=2 TAN=6 BLUE=7 WHITE=13 BLACK=15 |
| `n3a` | 纸纹：LINES=0 DOTS=1 GRID=2 |
| `oz9` | 书签：UNBOOKMARKED=0 BOOKMARKED=1 |
| `xw9` | PDF 盒模式：DOWNSCALING_AND_MAX_BOX=0 DOWNSCALING_AND_CROP_BOX=1 FIT_AND_CROP_BOX=2 |
| `y01` | 位置：BEFORE=0 AFTER=1 START_OF_DOC=2 END_OF_DOC=3 |
| `z4d` | 形状定义：NONE=0 LINE=1 POLYGON=2 NORMAL_SHAPE=3 |
| `z90` | ?：NONE=0 SINGLE=1 |
| `zsa` | 位宽：BITS_16=0 BITS_32=1 |
| `ww9` | 值类型：STRING=0 BOOLEAN=1 |
| `t8a` | **路径元素**：ATTRIBUTED_CUBIC=0/QUADRATIC=1/LINE=2/MOVE_TO=3 + NON_ATTRIBUTED_×4=4-7 |

## 要点

- `iq0` **稀疏 byte 码**（1,2,6,7,13,15）= 旧索引兼容——
  迁移必须保留非连续码，禁止按 ordinal 重排。
- `t8a` = 墨迹路径元素类型（`po4.a` 字段类型）——
  ATTRIBUTED/NON_ATTRIBUTED 两族×4 种（cubic/quadratic/
  line/moveTo）。
- `xw9` = PDF 渲染盒模式（maxBox/cropBox/downscaling）。
- `im` 锚点类型与 `v01.d()`（Boundary.type）同源。

## Harmony 决策

- 全部枚举 wire 码保留（iq0 稀疏码原样）。
- t8a 路径元素解码保留 attributed 语义。

## 产出

- fixture `d02-enum-sweep.mjs`（12 断言）。
- ADR-1002；中文报告。
