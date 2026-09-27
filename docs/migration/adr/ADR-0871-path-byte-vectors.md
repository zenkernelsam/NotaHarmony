# ADR-0871 — 路径编码为原始字节向量

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- encodedCenterPath/encodedCustomPath/encodedFillPath =
  **原始 byte[]**（自定打包路径编码），非结构向量；
  `ei7` 零拷贝迭代器直读 `cee.g(off)` ByteBuffer 切片；
  `nl8` 可变 byte 列表（×3/2 扩容）承接物化。
- styleMap 才是 yyd 结构向量——两类线型分明。

## Harmony 决策

路径编码以字节透传存储——不展开不解码；
与原版"表内自定格式字节流"语义一致。

## Parity 状态

等价（字节透传）。

## 验证

- `d02-path-byte-vectors.mjs`：11/11 通过。
- 全量 Replay 800 文件绿，见 Phase 927 提交。
