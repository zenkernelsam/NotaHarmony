# ADR-0918 — 结构写器尾部：xq3/vy7/ukb/ua0

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `vfj.d` xq3：t(8,24)+2 longs+嵌套 qo5——与读侧镜像。
- `fsi.b0` vy7=Margins：`{top@0,bottom@4,left@8,right@12}`
  16B + `ddg.l` 负值校验。
- `ddj.b` ukb：t(8,16)+2 longs `{start@0,end@8}`。
- `aa6.x0` ua0：t(8,64)+8 longs `{bits0..7@0..56}`——
  与 967 读侧逐字节镜像。

**z0c(21) 结构注册表 15/15 写器关闭。**

## Harmony 决策

Harmony encode* 与之逐字节对齐（既有 Replay 覆盖）。

## Parity 状态

等价。

## 验证

- `d02-struct-writer-tail.mjs`：11/11 通过。
