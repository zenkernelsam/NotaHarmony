# ADR-0954 — `d6c` FTS5 引擎实现 + `b50` AppSearch

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `d6c implements clc`，`b="room-fts5"`：a=全清
  （cfc）、b=wkc→glc 批量 UPSERT（写时折叠）、
  c=删、d=noteId 限定 LIKE、e=no-op、f=状态、
  g=FTS MATCH、h=`COUNT(*)`。
- `b50 implements clc`，`getName="appsearch"`
  （AppSearch 全实现）。

## Harmony 决策

d6c 平移 relationalStore（LIKE-only）；b50
fail-closed。

## Parity 状态

功能降级（FTS 语义经 LIKE 模拟）。

## 验证

- `d02-fts5-engine.mjs`：12/12 通过。
