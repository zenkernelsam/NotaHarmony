# Phase 1121 证据 — a79 活 note 聚合（x09 实现）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `a79 implements x09` = 活 note 对象

### 字段构成（~30）

- `ye9 b` = bundle 头；`kia c`、`Set d`、`ArrayList e`、`f1a f`、
  `int g`、`Map h`、`List i`、`ue4 j`。
- `cl2 k`/`D` = 惰性 map；`mja l`、`hja m` 持久 map。
- **7×`bja`**（o,p,q,F,G,H,J）+ **2×`uia`**（r,I）= 实体-map 快照。
- `qja n` = hja-backed 只读 map。
- **8×`yc6`**（t..z,A）= note 级 LWW 元数据寄存器！
- `m4c B` 块 spec；`lja C`；`nz9 K` 背景。
- 静态默认：`qed N`(size)、`vy7 O`(margins)、`float P`、
  `nz9 Q`、`w69 R`。

### `M` = w1b 属性描述（真实名泄漏）

```
title, defaultFontFamily, defaultFontSize, alignTextToLines,
layoutMode→LayoutMode, blockWrapSupport→BlockWrapSupport,
handwritingLanguage
```

= `l2d` SET_METADATA 的 8 个元数据寄存器字段（schema 名
`LayoutMode`/`BlockWrapSupport` 泄漏）。

### 访问器

`b()→Map`、`c()→tv6`(LayoutMode)、`d()→m4c`、`e()→Map`、
`f()→String`(title)、`g(List,ff2)`/`h(Collection,ny3,yx4,ff2)` suspend。

## Harmony 决策

- 活 note = bundle 头 + 8 元数据寄存器 + 7 实体-map 快照 +
  spec/背景/默认。
- 元数据 = LWW 寄存器数组（同实体属性模式）。

## 产出

- fixture `d02-live-note.mjs`（10 断言）。
- ADR-1065；中文报告。
