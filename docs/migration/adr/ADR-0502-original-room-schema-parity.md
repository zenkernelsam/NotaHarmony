# ADR-0502：原版 Room schema 逐表比对结论与 tool_state 索引对齐

日期：2026-09-22

## 状态

Accepted

## 背景

审计缺口清单 §3.2 指出：D-01（无页维度）、D-02（op-log 退化）、D-05（缺外键）三条
P0/P1 的基准证据此前仅为结构性推断 🟡，未真正拉取原版 `*Database_Impl` 建表 SQL
逐列对比。本阶段以 `decompiled_1.0.3` 中 Room 生成的 open-helper 回调
`e47.java`（DDL 集中在 322-411 行）、迁移 `ba8.java`、DAO 语句与资料库合并查询
`x17.java:143` 为基准，对全部 10 个原版 Room 库完成逐表比对。

## 决策

1. **统一 `nota.db` 对原版多库拆分继续保持**：原版按特性拆 10 个 Room 库
   （NoteState/NoteAsset/NoteBundleMetadata/RawLibraryState/Search/SearchIndex/
   Settings/Toolbox/Transcription/Learn），Harmony 以单库 + 严格 FK 图承载移植范围内
   的全部等价状态，FK 强度反而超过原版（原版自身表之间零外键）。
2. **`tool_state.tray_owner_id` 补原版同名索引**：原版声明
   `index_ToolStateEntity_tray_owner_id`（e47.java:380），Harmony
   `getToolStates()` 每次打开编辑器按该列过滤却未建索引。`DDL_INDEXES` 每次 open
   幂等执行，无需版本号迁移，故直接补
   `idx_tool_state_tray_owner ON tool_state(tray_owner_id)`。
3. **D-01/D-02/D-05 升级为 ✅ 闭环**：
   - D-01：原版 op 层本来就没有页维度（ClientOp 仅 noteId+opId），Harmony
     `page_element_snapshot`/`operation_log`/`original_*` 全链 note+page 维度更强；
   - D-02：Harmony `operation_log` 已具备真实 op 身份（op_id + timestamp/site 双
     UNIQUE、动作分组列、inbox/applied/deferred 三段式），不再是退化快照；
   - D-05：Harmony FK 图 + `verifyForeignKeys` 启动校验，覆盖并超越原版（原版零
     FK）。
4. **登记七条特性级差异（非已实现路径缺陷）**：软删/回收站模型（SCHEMA-D1）、
   每工具收藏/最近色井与线宽井（SCHEMA-D2）、文件夹 color/emoji/updatedAt
   （SCHEMA-D3）、zoomView/lastCodeBlockLanguage（SCHEMA-D4）、tape 工具与
   tapePattern 工具态（SCHEMA-D5）、索引队列/失败登记/草稿笔记（SCHEMA-D6）、
   同步校验与上传队列字段（SCHEMA-D7）。后续 Phase 按优先级单独实现，本阶段
   不预建死列。

## 原版依据

- `e47.java:322-411`：全部 10 库的 CREATE TABLE/INDEX DDL；
- `ba8.java:34-184`：Room 自动迁移（ClientNoteUpdate_new、SyncedFolderMetadata_new、
  PermanentlyDeletedNote、DraftNote、RecentColorWellEntity 等）；
- `x17.java:143`：ClientPivot CTE —— `deletedAt = MAX(DELETE.deletedAt)`，UNDELETE
  仅清除 synced 侧，`PermanentlyDeletedNote` 墓碑过滤；
- `leb.java:43-87`：UNDELETE 写入路径 —— upsert UNDELETE 行并删除 DELETE 行，
  保证 pivot 无条件 MAX 的正确性；
- `veb.java:629/661`：上传冲刷入口按类型组清空已上传行（EDIT+UNDELETE /
  DELETE+PERMANENTLY_DELETE）；
- `ve9.java:117`/`vb4.java:23`/`na4.java:583`/`wp1.java:532-552`：DAO 语句确认列
  语义与 upsert 形态；
- `strings.xml:830-832`：`feature_settings__recently_deleted` 及 “30 天自动彻底
  删除” 文案，确认软删为用户可见特性。

## 结果

- `DDL_INDEXES` 新增 `idx_tool_state_tray_owner`，旧库下次 open 自动获得；
- 新增 Replay `d02-original-room-schema-parity.mjs`（67 项断言），锁定全部映射表
  DDL 锚点、差异登记锚点，并以可执行模型复放 ClientPivot 合并语义；
- evidence 文档登记 SCHEMA-D1~D7，供后续 Phase 逐条实现。

## 未闭环

- SCHEMA-D1~D7 均为特性级缺口，需各自 Phase 实现（SCHEMA-D1 软删为 P1 优先）；
- 原版同步校验列（checksum/offsets/fingerprints）待真实同步通道落地时补齐；
- 真机上的查询计划/索引收益验证仍需设备验收。
