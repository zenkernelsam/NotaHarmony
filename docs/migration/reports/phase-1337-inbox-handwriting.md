# Phase 1337 报告 — 同步收件箱校验 + 手写转换

## 完成内容

- `SyncedOperationInbox` 入站校验：noteId 匹配+信封
  有效性+强制 server-time 有序+重复计数+u64 排序 —
  — 对照原版 SyncedOp 校验；`OriginalHandwriting*`
  8 文件手写转换层（Conversion/Planner/Policy/Locale/
  Context/Selection）对照 `dhb` —— MyScript 本体
  fail-closed、编排保真。

## 产出

- evidence `phase-1337-inbox-handwriting.md`
- fixture `d02-inbox-handwriting.mjs`（10/10）
- ADR-1280
