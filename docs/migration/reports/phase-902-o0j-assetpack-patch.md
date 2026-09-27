# Phase 902 报告 — `o0j.b` 归类为 GMS AssetPacks 补丁器

## 范围

归类 878 发现的二进制补丁应用器。纯审计，fail-closed。

## 原版发现

- `o0j.b` = Play Asset Delivery 增量补丁应用器——
  `jjg` 输出汇带 `assetpacks.p` 字段（GMS slice 输出流）；
  无 Notability 自有调用点。
- 格式完整恢复：magic 0xD1FFD1FF、version 4、
  opcode 0/F7-FB（literal+基文件拷贝）+ 守卫集。

## Harmony 结论

fail-closed：GMS 依赖不可达；同步走 op-bundle。

## 产出

- 证据：`phase-902-o0j-assetpack-patch.md`
- Fixture：`d02-o0j-assetpack-patch.mjs`（12/12）
- ADR-0846；全量 Replay 775 文件绿。
