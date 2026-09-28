# ADR-0915 — 字符串写器双路径与 v71 零拷贝

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`dbj.c(CharSequence,a)`：

- 普通 CharSequence → `a.l`（builder 内 UTF-8 编码，
  ASCII 快扫 + `zq6` 编码器）。
- `v71`（ByteBufferBackedCharSequence = 原生 UTF-8
  字节视图）→ `sg5.b` ThreadLocal 池化缓冲 →
  `f(bb)`/`e()` → `a.m` byte-vector 直通。
- `a.m`：NUL 终止 + `D(1,len,1)` + `put(bb)` + `o()`。

## Harmony 决策

Harmony encodeString 单路径等价（UTF-8+长度+NUL）；
v71 直通为原生端零拷贝优化，无可移植差异。

## Parity 状态

等价。

## 验证

- `d02-string-writer.mjs`：15/15 通过。
