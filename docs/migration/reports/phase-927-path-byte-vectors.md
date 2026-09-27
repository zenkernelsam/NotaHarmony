# Phase 927 报告 — 路径字节向量层实名

## 范围

路径编码线型确认 + ei7/nl8 实名。纯审计。

## 原版发现

- 路径三字段为原始 byte[] 自定打包编码；ei7 零拷贝
  迭代器直读 ByteBuffer 切片；nl8 可变 byte 列表
  ×3/2 扩容。
- styleMap 为 yyd 结构向量——两类线型分明。

## Harmony 核对

字节透传语义正确。

## 产出

- 证据：`phase-927-path-byte-vectors.md`
- Fixture：`d02-path-byte-vectors.mjs`（11/11）
- ADR-0871；全量 Replay 800 文件绿。
