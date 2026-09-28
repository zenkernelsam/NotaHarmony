# Phase 970 报告 — FlatBufferBuilder 原语全图

## 范围

com/google/flatbuffers/a.java。纯审计。

## 原版发现

- 写侧原语层完整定名：字段 a..n、生命周期 C/D/o/n/p、
  标量/偏移/结构写、required 检查、vtable 裁剪去重。
- `l`=forceDefaults 实证为 setter 三态写的底层开关。
- `a(c8d,bb)` 池化构造 = Phase 955 分配器闭环。

## 产出

- 证据：`phase-970-builder-primitives.md`
- Fixture：`d02-builder-primitives.mjs`（21/21）
- ADR-0914；全量 Replay 见本提交。
