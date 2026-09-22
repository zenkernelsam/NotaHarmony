# 修复总结 — Phase 576 原版 Room Schema 逐表审计 + tool_state.tape_pattern 补齐

日期：2026-09-22
提交范围：`DatabaseHelper.ets`、`BrushTypes.ets`、`ToolRepositoryImpl.ets`、
`d02-original-tool-state-tape-pattern.mjs`、ADR-0547、证据文档、跟踪文档。

## 背景

审计清单 #1 优先级条目：原版 Room schema 逐表对比（3.2）。原版全部 DDL
汇编于 `decompiled_1.0.3/sources/defpackage/e47.java`（40 表 +
`room_master_table`），`NoteStateDatabase_Impl.java` 记录迁移 1→2→3→4。

## 审计结论

逐表对照矩阵见
`docs/migration/evidence/original-room-schema-table-audit-harmony-2026-09-22.md`。
要点：

- **唯一可执行缺口**：`ToolStateEntity.tapePattern INTEGER DEFAULT NULL`
  在 Harmony `tool_state` 缺失——REVIEW/胶带工具的图案选择无法持久化。
- **D-01/D-02 升级**：原版 `ClientOp` 无 page 列（op payload 内携带），
  Harmony page-in-payload 为原版忠实；`operation_log` 为结构化超集。
- **D-05 升级**：原版仅 Toolbox→Tray→Tool 链 + WorkSpec 用 FK；Harmony
  `note_meta`/`page_info` 下游全 CASCADE，覆盖面超过原版。
- AI/学习域（Learn/Quiz/Summary/transcription）与 WorkManager 运行时表
  无本地等价，fail-closed（ADR-0502 已述）。

## 修复（schema v71）

1. `DDL_TOOL_STATE` 增加 `tape_pattern INTEGER`（可空、无 DEFAULT/CHECK，
   列位对齐原版：selectedWidthSizeWellIndex 之后、selectionIsFreehand 之前）。
2. `MIGRATIONS[71]`：`ALTER TABLE tool_state ADD COLUMN tape_pattern INTEGER`；
   `DB_VERSION` 70→71。
3. `ToolState.tapePattern?: TapePattern | null`；`rowToState` 用
   `isColumnNull` 判空，`toBucket`/`cloneState` 用 `?? null` 往返。
   `EditorViewModel.cloneState`（快照/回填/updateActiveState 共用）同步补
   字段——否则任何工具变更会静默抹掉已存图案。

## 验证

- 专项 replay：`d02-original-tool-state-tape-pattern.mjs` 17/17 通过
  （版本、迁移语句、DDL 列位/可空性、模型/仓储往返、相邻表不变量）。
- 全量 desktop replay：471/471 绿。
- `note@default` + `note@ohosTest` 双 HAP 构建成功，无新增 ArkTS 错误。
