# ADR-0766 — 数据库拓扑合并：13 Room 库 → 统一 RDB

## 状态

已接受（登记既成架构决定）。

## 背景

原版采用按域拆分的 Room 数据库集群：1.0.x 为 10 库，1.4.2 增至 13 库
（新增 CalendarDatabase v2、GalleryMutationDatabase、CustomTemplatesDatabase），
约 45 个实体，各库独立版本号与迁移链（NoteState v4→v5、Learn→v7、
Toolbox/RawLibraryState v8 等）。

Harmony 端在移植早期即采用了不同拓扑：单一 `relationalStore` 统一库
（`DB_VERSION=71`，自增版本阶梯迁移器），约 83 张表，其中 `original_*`
族 40+ 表为移植期新增的逐字段 LWW 胜者解析层。

## 决定

1. **维持统一 RDB 拓扑**，不拆回 13 库：relationalStore 单库事务边界覆盖
   原版的跨库弱一致性语义；迁移阶梯已承载 71 个版本的演进。
2. **域映射登记**：原版各库实体全部映射至 Harmony 表（见证据文档 §三），
   无表级遗漏；Learn/Calendar/Gallery/Transcription 属后端功能库，
   与各集群 fail-closed ADR 一致缺席。
3. **版本增量登记**：原版库级版本差（NoteState 4→5 对应 785 列增量、
   Learn v1→v7 重建、Calendar 上线即 v2）记入证据文档供回溯。
4. **新增架构层登记**：Harmony 的 `original_*_winner`/`history_checkpoint`
   表族为移植期冲突消解与撤销检查点机制，无原版对应物，明确标注为
   Harmony-era 架构而非原版行为。

## 后果

- 持久层拓扑闭合：原版库清单、实体清单、迁移链、版本增量全登记。
- 新增 `d02-database-topology.mjs` 回归：库数、迁移链、实体清单、
  Harmony 域覆盖。

## 已验证

- `d02-database-topology.mjs`：13/13。
- 全量 Desktop Replay + clean/default、`note@ohosTest` HAP 构建（随 Phase 822 提交）。
