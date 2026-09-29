# ADR-0986 — ID 语义细节

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ttf` UUID 全语义：`a()→byte[]`+`hashCode=I^J`+
  compareTo/equals+canonical toString。
- `utf` = wire-UUID（a()+c()+d() 三访问器）。
- `cxc.C()` = `J.getInt(I+8)` = **页序@offset+8**。
- `xwd.b()` = offset+ByteBuffer 绑定。

## Harmony 决策

UUID 全语义+cxc 页序 offset-8 读保留。

## Parity 状态

等价。

## 验证

- `d02-id-semantics.mjs`：10/10 通过。
