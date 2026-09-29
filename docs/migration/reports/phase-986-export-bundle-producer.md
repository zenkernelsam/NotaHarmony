# Phase 986 报告 — 导出 NoteBundle 生产者 + haa 全枚举

## 范围

yk9/fsi.P/haa。纯审计。

## 原版发现

- **`haa` 32 序数全表** pinned（NONE→MODIFY_COMMENT）。
- `fsi.P` = 导出过滤（transient+26+29 排除）。
- `yk9` = 分享/导出 .note 包生产者：过滤→排序→
  q4j.c 写→**复读校验→ree.b 二次序列化**。
- 资产清单：背景 PDF（SET_METADATA/CREATE_PAGE）+
  图片（CREATE_BLOCK）+ 录音（CREATE_RECORDING，可选）+
  MODIFY_PAGE PDF——按 ua0 去重。

## 产出

- 证据：`phase-986-export-bundle-producer.md`
- Fixture：`d02-export-bundle.mjs`（47/47）
- ADR-0930；全量 Replay 见本提交。
