# Phase 1117 报告 — 字节漏斗 + op 访问器 + holder 注册表

## 完成内容

- `v71` = 只写字节 CharSequence（e()/f(bb) 通道）。
- `uq9` op 访问器 + 三键等值。
- `sg5` holder 注册表泄漏真实 schema 名
  （core.flatbuffers.{Id,SeqId,StyleMap,RecordingSegment,Point,
  Size,ModifyPosition,DuplicateOp,OpAck,Op}）。

## 产出

- evidence `phase-1117-byte-funnel.md`
- fixture `d02-byte-funnel.mjs`（10/10）
- ADR-1061
