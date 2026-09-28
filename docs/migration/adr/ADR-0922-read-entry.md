# ADR-0922 — 读侧入口 uhj.n + ic3 标志集

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `uhj.n(ByteBuffer)` = NoteBundle 根读入口：LE +
  `d(pos+getInt(pos))` 标准 root-uoffset 解析。
- `ic3` = 6 位标志集 `{1,2,4,8,16,32}`+mask 63+组合
  + 反射命名注册（`hc3{b,name}`）；`uhj` 兼标志
  提供者（l/m/o/p/q → ic3.e/h/f/g/j）。

## Harmony 决策

读入口语义等价（decodeNoteBundle 同法）；ic3 用途
随上层语义待定，线型无影响。

## Parity 状态

等价。

## 验证

- `d02-read-entry.mjs`：11/11 通过。
