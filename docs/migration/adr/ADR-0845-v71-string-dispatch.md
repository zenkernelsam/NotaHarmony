# ADR-0845 — `dbj.c` 字符串写派发 + `v71` 原始 UTF-8 视图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `dbj.c(cs,builder)`：v71 实例 → `builder.m(bb)` 原始
  字节串写（`sg5.b` ThreadLocal 暂存）；否则 →
  `builder.l(cs)` createString。
- `v71` = `ByteBufferBackedCharSequence`：char 访问抛
  UnsupportedOperationException，仅供整块字节拷贝——
  收到字符串以原始 UTF-8 字节持有。
- 语义：**字节精确往返**——收到的字符串重写时原样
  透传，不经 UTF-8 重编码。

## Harmony 决策

新建字符串正常编码；**接收到的原始字符串须保留
byte 级回写能力**（reader 槽→编码器透传），不得仅
以解码后 String 往返（可能丢失非常规字节）。

## Parity 状态

条件等价（透传能力为约束性要求；实现侧需 reader→
encoder 字节级通路）。

## 验证

- `d02-v71-string-dispatch.mjs`：12/12 通过。
- 全量 Replay 774 文件绿，见 Phase 901 提交。
