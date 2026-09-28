# ADR-0923 — 笔记 blob 加载路径

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

加载链：`qud`（mmap 容器，关即删除非 N）→
`uhj.n(qud.J)` → `uae` 视图 → **u16 无符号
schemaVersion 闸**（`ba6.w(bundle&0xFFFF,
rgc.a&0xFFFF)>0` 则走更新文件路径/抛 Stale）→
`lv2.T` ops 物化。`nce` 为同步存储外壳（延迟 ops
文件旁路："Skipping unreadable deferred ops file"）。

## Harmony 决策

Harmony `loadNote` 同构（mmap→根读→版本闸→物化）；
u16 比较语义已在既有 Replay 锁定。

## Parity 状态

等价。

## 验证

- `d02-blob-load-path.mjs`：16/16 通过。
