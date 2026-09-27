# ADR-0846 — `o0j.b` = GMS AssetPacks 补丁器（fail-closed）

## 状态

accepted（fail-closed 归档，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `o0j.b` = Google Play Asset Delivery 增量补丁应用器
  （`jjg`=assetpacks slice OutputStream，`c`/`aig`=包
  内容基抽象/范围流）。
- 格式：magic `0xD1FFD1FF`、version 4；opcode 0=END、
  F7/F8=literal 拷贝（u16/i32 长）、F9/FA/FB=基文件
  拷贝（u16 偏移+变长）；全守卫集。
- 无 Notability 自有调用点——GMS SDK 内部件。

## Harmony 决策

**fail-closed**：Harmony 无 Play Asset Delivery；同步
走自有 op-bundle。不实现此补丁通道。

## Parity 状态

fail-closed（GMS 内部件归档，格式备查完整）。

## 验证

- `d02-o0j-assetpack-patch.mjs`：12/12 通过。
- 全量 Replay 775 文件绿，见 Phase 902 提交。
