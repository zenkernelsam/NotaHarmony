# Phase 909 证据 — `dm2` = `CreateInk` 全字段读图

## 目的

实名墨迹创建 op 载荷全部 20 字段（870 写侧注册的
读侧补全）。`decompiled_1.0.3`，toString+accessor 实证。

## `dm2` = `CreateInk`（toString 实证 20 字段）

`CreateInk(page=, origin=, rotation=, scale=, tool=,
style=, tapePattern=, color=, width=, encodedCenterPath=,
encodedCustomPath=, encodedFillPath=, fillColor=,
styleMap=, zIndex=, audioDuration=, nibAngle=,
nibFlatness=, inkEffects=, inkEffectsTinted=)`

## accessor→字段图（c(4+2i)）

| 访问器 | c(N) | 字段 | 类型 | 语义 |
|--------|------|------|------|------|
| `t()` | c(4) | f0 | `cxc` | **page**（页面位置） |
| `C(fqa)` | c(6) | f1 | `fqa` | **origin** |
| `u()` | c(8) | f2 | `Float` | **rotation** |
| `v()` | c(10) | f3 | `qed` 内联 | **scale** |
| `z()` | c(12) | f4 | `u16` byte | **tool**（笔类型） |
| `w()` | c(14) | f5 | `t16` byte | **style** |
| `y()` | c(16) | f6 | `ife` byte | **tapePattern** |
| `k()` | c(18) | f7 | `hu1` 内联 | **color** |
| `A()` | c(20) | f8 | `float` | **width** |
| — | c(22) | f9 | 向量 | **encodedCenterPath** |
| `l()` | c(24) | f10 | Integer/向量 | **encodedCustomPath** |
| `m()` | c(26) | f11 | Integer/向量 | **encodedFillPath** |
| `n()` | c(28) | f12 | `hu1` 内联 | **fillColor** |
| `x()`/`D()` | c(30) | f13 | Integer/`yyd` | **styleMap** |
| `B()` | c(32) | f14 | `tmf` ULong | **zIndex** |
| `j()` | c(34) | f15 | `mmf` UInt | **audioDuration** |
| `q()` | c(36) | f16 | `ymf` UShort | **nibAngle** |
| `r()` | c(38) | f17 | `ymf` UShort | **nibFlatness** |
| `o()` | c(40) | f18 | `long` | **inkEffects**（位集） |
| `p()` | c(42) | f19 | `boolean` | **inkEffectsTinted** |

## 枚举读法（`z/w/y`）

`byte → nz3 条目`：`(b - min.I)` 范围检查，越界→
entries[0]——u16/t16/ife 与 haa 同款前向兼容回退。

## 路径物化器

`lv2.w/B/E/f0` = encodedCenterPath/encodedCustomPath/
encodedFillPath/styleMap 向量物化（lv2 静态族）。

## Harmony 侧

`OriginalInkOperation`/`OriginalCreateInk*` 编码字段 ↔
此 20 槽图；工具/样式/胶带枚举 byte 读法对齐；
nibAngle/Flatness UShort、audioDuration UInt、
inkEffects ULong 位集语义对齐。

## 结论

CreateInk 20 字段读写全闭（870 写 + 909 读）；
最大 op 载荷实名完毕。纯文档+fixture 阶段。
