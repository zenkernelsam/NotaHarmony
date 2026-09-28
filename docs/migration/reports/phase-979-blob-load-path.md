# Phase 979 报告 — 笔记 blob 加载路径

## 范围

qud/zac/uae/nce/ba6/lv2。纯审计。

## 原版发现

- `qud` = mmap 化 note-blob（J=payload，关即删）。
- 加载链：mmap→uhj.n→uae 视图→**u16 schemaVersion
  闸**（新版 bundle 走 StaleSyncedNote 路径）→
  lv2.T ops 物化。
- `nce` = 同步存储外壳，含延迟 ops 文件容错读。

## 产出

- 证据：`phase-979-blob-load-path.md`
- Fixture：`d02-blob-load-path.mjs`（16/16）
- ADR-0923；全量 Replay 见本提交。
