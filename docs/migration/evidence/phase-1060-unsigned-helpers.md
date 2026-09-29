# Phase 1060 证据 — Kotlin 无符号值类族 + 助手层

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 无符号值类族（Kotlin UByte/UShort/UInt/ULong 混淆名）

| 类 | 底类型 | toString/compareTo 证据 |
|---|---|---|
| `cmf` | **UByte**（byte） | `String.valueOf(b & 255)`；cmp `I & 255` |
| `ymf` | **UShort**（short） | `s & 65535` |
| `led` | **UShort**（short） | 同上形态（Ph1039 schemaVersion） |
| `mmf` | **UInt**（int） | `(long)i & 0xFFFFFFFFL`；cmp `I^0x80000000` |
| `tmf` | **ULong**（long） | `njj.j0(10,I)` 无符号 fmt |

由此修正：serverTime/audioTime/zIndex/schemaVersion/
unicodeScalar 均为**无符号**语义——按符号位解读会错。

## `njj.j0(int radix, long)` = ULong.toString(radix)

负值走 `((j>>>1)/radix)<<1` 高部 + 余数拼接——
Kotlin 无符号长除法实现（`cq.C`=radix 校验）。

## 助手层

| 类 | 职能 |
|---|---|
| `rgc.b(str)` | `IllegalStateException("Unknown type '..' will lead to data loss...")` fail-loud |
| `o14` | Kotlin intrinsics throw 簇（i=AssertionError, k/l/n=IllegalState, h=IllegalArgument, t=unreachable） |
| `ba6.o/m/w/s` | Objects.equals / Float.equals / Integer.compare / 复合键 |
| `fa2`/`od4`/`vh2`/`x82` | StringBuilder concat/UTF-8 codegen 助手 |
| `s5c.q`/`o14.i` | 格式化警告/required 缺字段警告 |

## Harmony 决策

- **全部序数/ID/时间戳按无符号处理**——ArkTS 用
  BigInt/显式 `>>>0`/`&0xFF` 等价；禁用有符号比较。
- `rgc.b` fail-loud 文案保留（写盘数据丢失警示）。

## 产出

- fixture `d02-unsigned-helpers.mjs`（12 断言）。
- ADR-1004；中文报告。
