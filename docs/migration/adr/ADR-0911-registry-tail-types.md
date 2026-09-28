# ADR-0911 — z0c 注册表尾部 8 类型定名

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

最后 8 个未命名注册类型全部定名：`vt9`=OpsBundle、
`q89`=NoteMutationResponse、`nz9`=PageBackground、
`sw9`=PDFAsset、`sdf`=TransientInteraction、
`ua0`=AssetHash（**64B/8×long** = SHA-512 尺寸）、
`p9`=AcknowledgeAppendedOpsEvent、`k3a`=Paper。

z0c 写侧注册表 **80/80 项关闭**：15 xwd + 65 cee。

## Harmony 决策

- `ua0` 64B 哈希 → Harmony 资产哈希字段按 8×uint64
  或 SHA-512 字节串表示（等价）。
- `vt9` OpsBundle = ops-blob 外层——原稿 note 文件
  ops 段容器语义已在 905/965 覆盖。

## Parity 状态

等价。

## 验证

- `d02-registry-tail-types.mjs`：17/17 通过。
