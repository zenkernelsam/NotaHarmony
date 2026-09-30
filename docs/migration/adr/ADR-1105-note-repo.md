# ADR-1105：data/note 仓储层

## 状态

已接受（Phase 1161）。

## 决策

- Room `@Database`×3（NoteAsset/NoteBundleMetadata/
  NoteState，`x5c`基）+ `_Impl` 生成 + DAO → Harmony
  `@ohos.data.relationalStore` + 手写 DAO。
- `androidx.work` 资产传输 Worker → Harmony
  `@ohos.work.scheduler` 后台任务。
- 5 同步异常（AccessDenied/CorruptedSyncedOp/
  NoteHasNoOps/NoteOpsNotFound/StaleSyncedNote）语义保。

## 依据

命名 `data/note/` Room/Worker/异常类。

## 后果

Harmony：relationalStore 持久 + 后台同步 Worker + 同名
异常分类；`_Impl` 手写（无 codegen）。
