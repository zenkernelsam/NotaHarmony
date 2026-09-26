# Phase 764：原版 1.4.2 自定义模板数据库 Schema 登记

> 日期：2026-09-29
> 证据：`docs/migration/evidence/phase-764-original-custom-template-schema.md`
> 上层处置：`docs/migration/adr/ADR-0708-original-1.4.2-version-delta-scope.md`
> Replay：`d02-original-custom-template-schema.mjs`（6 断言，全绿）
> 性质：版本差证据登记；无 Harmony 代码变更。

## 登记结果

- `CustomTemplatesDatabase`（Room）声明 `CustomTemplate` +
  `PendingTemplateDeletion` 两实体；
- 由 Room 生成 INSERT 还原 `CustomTemplate` 13 列：
  `id/name/interactive/repeats/createdAt/favoritedAt/assetId/
  syncedName/uploadState/origin/pageCount/pageWidth/pageHeight`——
  覆盖 interactive/repeat 模板开关、收藏排序、云同步状态机与页几何；
- `PendingTemplateDeletion(assetId)` 为墓碑式待删队列，与本仓
  asset-detach 软删+回收管线同型。

## 处置

版本差·待审：本地库结构可由 Harmony RelationalStore 等价，
真正的移植依赖在模板资产序列化格式与 interactive/repeats 语义；
同步侧字段（uploadState/origin/assetId）属后端边界。
Replay 6 断言全绿；无源码变更；T-042 输入。
