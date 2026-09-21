# 修复总结 — Phase 530 原版 Room schema 逐表比对

日期：2026-09-22

## 问题

审计缺口清单 §3.2 标记「原版 Room schema 未逐表比对」为投入产出比最高的补审卡：
D-01（无页维度）、D-02（op-log 退化）、D-05（缺外键）三条 P0/P1 的基准证据此前
仅为结构性推断 🟡，从未拉取原版 `*Database_Impl` 建表 SQL 逐列对比。本阶段以
`decompiled_1.0.3` 的 Room open-helper 回调 `e47.java`（全库 DDL 集中处）、迁移
`ba8.java`、DAO 语句与资料库 `x17.java:143` ClientPivot 查询为基准，对全部 10 个
原版 Room 库完成逐表比对。

## 修复

- 新增 `DDL_INDEXES` 项 `idx_tool_state_tray_owner ON tool_state(tray_owner_id)`，
  对齐原版 `index_ToolStateEntity_tray_owner_id`（`e47.java:380`）；Harmony
  `getToolStates()` 每次打开编辑器按该列过滤，此前无索引。`DDL_INDEXES` 在每次
  open 幂等执行（`DatabaseManager.ets:215-217`），旧库无需版本号迁移。
- D-01/D-02/D-05 三条升级为 ✅ 闭环：原版 op 层本无页维度，Harmony 页维度、真实
  op 身份与完整 FK 图均达到或超过原版。
- 登记七条特性级差异 SCHEMA-D1~D7（详见 evidence 与 ADR-0502）：最值得关注的
  是 **笔记软删/回收站模型** —— 原版以 `ClientNoteUpdate` 记录
  EDIT/DELETE/UNDELETE/PERMANENTLY_DELETE，`x17.java:143` ClientPivot 合并
  `deletedAt`，`PermanentlyDeletedNote` 作墓碑，设置页有 “Recently Deleted” 入口并
  30 天自动彻底清除；Harmony 目前只有硬删。该特性连同其余六条差异留给后续
  Phase 实现，本阶段不预建死列。

## 证据与验证

- Phase 530 schema parity 专项 Replay：`67/67`；
- ArkTS：`DatabaseHelper.ets` 无新增错误；
- 全量 Desktop Replay：`REPLAY_FILES=425 PASSED=425 FAILED_FILES=0`；
- clean、`note@ohosTest`、`note@default` 静态构建：见下文验证记录；
- 未启动模拟器、虚拟机、真机或 Hypium，`T-042` 继续保持整个 Goal 的最后任务。
