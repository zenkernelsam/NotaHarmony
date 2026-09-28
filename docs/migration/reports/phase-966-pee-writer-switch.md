# Phase 966 报告 — pee 合并写器 + setter 三态写 + wa0

## 范围

z0c.java（pee 匿名类）、jgh/ngh/k1j/wa0。纯审计。

## 原版发现

- `pee` = ~28-case 合并 wx4 写器：setter 全家 + 文本 op
  + 资产表 + 杂项表的写侧分派全名录。
- setter 写器 = `C(1)` + `l=true` 强制写标志：null 不写、
  非 null 必写（即便默认值）——三态语义的写侧实现。
- `wa0` = AssetMetadata{assetHash,fileName,mimeType,
  fileSize}，required 三连。

## 产出

- 证据：`phase-966-pee-writer-switch.md`
- Fixture：`d02-pee-writer-switch.mjs`（38/38）
- ADR-0910；全量 Replay 见本提交。
