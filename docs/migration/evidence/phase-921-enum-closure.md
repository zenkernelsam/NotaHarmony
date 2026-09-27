# Phase 921 证据 — 枚举 setter 族 + 枚举值全集

## 目的

段落 setter 与剩余枚举值实名——枚举层闭合。

## 枚举 setter（单值槽 {value@c(4)} 延续）

| 类 | 名称 | 载荷类型 |
|----|------|---------|
| `o2d` | `SetParagraphAlignment{value:r4a}` | 枚举 |
| `j2d` | `SetDecoratorStyle{value:fy2}` | 枚举 |
| `a3d` | `SetUInt8{value:cmf}` | **UByte** |
| `b3d` | `SetWritingDirection{value:bcg}` | 枚举 |
| `n2d` | `SetPaper{value:k3a}` | 表 |
| `p2d` | `SetRect{value:bmb}` | 结构 |

## 枚举值全集

- `r4a` = **ParagraphAlignment{LEFT=1,CENTER=2,
  RIGHT=3}** —— **1 基**（0 留给缺席）。
- `fy2` = **DecoratorStyle{NONE=0,BULLET=1,NUMBER=2,
  CHECK_BOX=3,BLOCK_QUOTE=4,CODE_BLOCK=5}** ——
  ar6 DECORATOR_STYLE=6 里程碑。
- `bcg` = **WritingDirection{LEFT_TO_RIGHT=0,
  RIGHT_TO_LEFT=1}** —— ar6 WRITING_DIRECTION=10。
- `ife` = **TapePattern{STRIPES=0,GRID=1,DOTS=2,
  PLAIN=3,STARS=4,FLOWERS=5,HEARTS=6,WAVES=7,
  CHECKERS=8}** —— 9 图案，TAPE_PATTERN=9/
  MODIFY_INK_TAPE_PATTERN=13 里程碑。
- `ive` = **TextWrap{PIXEL_ALIGN=0,NO_WRAP=1}**。
- `cmf` = **Kotlin UByte** 值类（`byte I` +
  `& 255` 无符号比较）——indentLevel/k3a f5 类型；
  UByte/UInt/UShort/ULong 无符号四族全集闭
  （cmf/mmf/ymf/tmf）。

## Harmony 核对

枚举值与 1 基对齐（r4a）；TapePattern 9 值、
DecoratorStyle 6 值、WritingDirection 2 值对齐；
cmf=UByte 位宽确认。

## 结论

setter 族 12 表全闭；枚举全集实名（r4a/fy2/bcg/
ife/ive/tv6/dz0/y01/oz9/u16/t16/n3a/cmf）。
