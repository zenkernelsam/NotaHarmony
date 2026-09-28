# ADR-0920 — hu1 Color RGBA 内联结构 + ao2 required

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `hu1` = Color 4B xwd：`{bitsR@0,G@1,B@2,A@3}`，
  分量 `cmf` UByte；`z5c.P` 写器 t(1,4)+u×4（推 A,B,G,R
  落位 RGBA 线序）。**所有 color 字段内联此结构**。
- ao2 required = `{page:f0, origin:f1, f5, color:f9}`；
  a() 校验含 "Cannot create shapes with variable width
  ink"、"ink_effects require Pen/Highlighter"。
- `x4d` 实为合成 lambda 类，非枚举（订正 912）。

## Harmony 决策

Harmony 颜色编码 = RGBA 字节序内联 4B；与
encodeColor 实现对齐核对。

## Parity 状态

等价。

## 验证

- `d02-hu1-color.mjs`：14/14 通过。
