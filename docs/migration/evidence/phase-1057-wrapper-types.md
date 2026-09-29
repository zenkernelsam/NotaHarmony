# Phase 1057 证据 — Set× 包装族 + 胶带/peer/选区类型

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## Set× 包装族（样式字段的可空联合）

| 类 | toString | 用途 |
|---|---|---|
| `z2d` | SetString{value} | title/语言（Ph1054） |
| `m2d` | SetPageBackground{value} | 背景（Ph1046） |
| `z1d` | SetBool | me8 bold 等 |
| `g2d` | SetColor | me8 foregroundColor 等 |
| `k2d` | SetFloat | me8 size 等 |
| `v01` | **Boundary{location:cxc, type}**（xwd struct） | me8/he8 start/end 锚点 |

Set× = "set-or-unset" 字段包装：出现=设置，缺省=不改。
`v01.d()` type 为锚点类型枚举（io1 校验同源）。

## 胶带图案 `ife`（9 值 byte）

STRIPES=0 GRID=1 DOTS=2 PLAIN=3 STARS=4 FLOWERS=5
HEARTS=6 WAVES=7 CHECKERS=8

## peer/选区

- `u76` peer 工具：POINTER=0 PEN=1 HIGHLIGHTER=2 ERASER=3
  （子集于 u16）。
- `qqe` = TextSelection{anchor, focus}——peer 广播用。
- `akb` = RecordingAsset{metadata}。

## Harmony 决策

- Set× 包装→`Set<T>|unset` 联合；锚点 Boundary{location,
  type} 保留；ife/u76 wire 对齐。

## 产出

- fixture `d02-wrapper-types.mjs`（12 断言）。
- ADR-1001；中文报告。
