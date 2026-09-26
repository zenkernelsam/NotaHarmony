# Phase 840 — `data/note/ops` 同步操作层审计

证据：`decompiled_1.4.2/sources/com/gingerlabs/notability/data/note/ops/`
+ Harmony `note/src/main/ets/data/OperationSyncCoordinator.ets` 对照

## 一、原版结构

```
data/note/ops/
├── database/NoteBundleMetadataDatabase(+_Impl)   # 笔记束元数据 Room DB
└── synced/                                        # 同步失败类型学（6 类）
    ├── AccessDeniedException        # 403 级拒绝
    ├── CorruptedSyncedOpException   # 操作数据损坏
    ├── NoteHasNoOpsException        # 笔记无操作序列
    ├── NoteOpsGoneException         # 服务端已清除（410）extends NoteOpsNotFound
    ├── NoteOpsNotFoundException     # 404 不存在
    └── StaleSyncedNoteException     # 陈旧基线（版本漂移）
```

**语义**：操作序列（ops）级同步的失败分类学——六类类型化异常
分别对应访问拒绝/数据损坏/空序列/服务端清除/未找到/陈旧基线，
为类型化恢复路径服务（重拉快照/丢弃/重新上传等）。

## 二、Harmony 侧对照

`OperationSyncCoordinator.ets` 有 7 处 `throw new Error(...)`：
`request is invalid` / `site was not persisted` / `session identity
is invalid` / `batch identity is invalid` / `ID does not match clock
identity` / `upload acknowledgement does not match` ×2——

**全部非类型化 Error**（字符串消息），无 6 类同步失败分类。

## 三、差异登记

| 原版 | Harmony |
|------|---------|
| 6 类型化异常（类型即恢复路径信号） | 7 处字符串 Error（无类型标签） |
| NoteBundleMetadataDatabase Room | Harmony 统一 RDB 内的等价表（822 已映射） |

**结论**：ops 同步失败分类学为**登记缺口**——Harmony 按消息
字符串区分失败，未恢复类型化恢复路径语义。由于后端不可达
（同步面 fail-closed 已登记），该缺口为文档级而非行为级。
