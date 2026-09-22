# ADR-0547: tool_state 补齐原版 tapePattern 可空列（schema v71）

## Status

Accepted, 2026-09-22.

## Context

Phase 576 对 `decompiled_1.0.3/sources/defpackage/e47.java` 的全部 Room
DDL 做逐表对比。绝大多数原版表已在 Harmony 有等价落点（见
`docs/migration/evidence/original-room-schema-table-audit-harmony-2026-09-22.md`
的对照矩阵），唯一可执行缺口是 `ToolStateEntity` 的：

```sql
`tapePattern` INTEGER DEFAULT NULL
```

该列持久化 REVIEW/胶带工具的选中图案（跨重启）。Harmony 已具备
`TapePattern` 枚举（0..8）与逐笔画 `original_ink_state` 的
tape_pattern 寄存器族，但 `tool_state` 缺列，REVIEW 工具的图案选择无法
持久化。

## Decision

- `DDL_TOOL_STATE` 增加 `tape_pattern INTEGER`：可空、无 `DEFAULT`、无
  `CHECK`，与原版 DDL 完全一致（原版无 CHECK，图案合法性由上层保证）。
- 列位置对齐原版：置于 `selected_width_well_index` 与
  `selection_is_freehand` 之间（Room 不保证列序语义，但保持阅读一致性）。
- `MIGRATIONS[71]` 单条 `ALTER TABLE`，存量行回填 NULL——与原版
  `DEFAULT NULL` 等价。
- `ToolState.tapePattern?: TapePattern | null`；仓储读写走
  `isColumnNull`/`?? null` 往返（与 `last_used_tool_id` 同型处理）。

## Consequences

- REVIEW/胶带工具落地时无需二次迁移，工具图案即可持久化。
- 非 REVIEW 工具行恒为 NULL，与原版语义一致。
- 审计条目 D-01/D-02/D-05 升级为"原版忠实/超集"结论（见证据文档）。

## Alternatives Considered

- 等 REVIEW 工具落地再加列：会多一次迁移且 Phase 576 的逐表审计留下未
  闭环缺口；单列 ALTER 成本极低，选择即时补齐。
- 加 `CHECK (tape_pattern BETWEEN 0 AND 8)`：原版无此约束，加严会偏离
  原版行为（写入越界值时原版不报错），拒绝。
