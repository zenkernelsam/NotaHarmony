# ADR-0784 — 同步操作失败分类学登记

- 状态：已接受（文档级缺口登记）
- 证据：`docs/migration/evidence/phase-840-synced-ops.md`
- 回放：`docs/migration/replays/d02-synced-ops.mjs`（13/13）

## 决定

1. 原版 `synced/` 六类类型化异常（含 `Gone ⊂ NotFound`
   层级）为类型化恢复路径信号；Harmony
   `OperationSyncCoordinator` 用非类型化字符串 Error——
   **登记为缺口**。
2. 该缺口为**文档级而非行为级**：后端同步面已整体
   fail-closed（无可达后端），类型化恢复路径无触发场景。
   若未来接入后端，按六类分类学补齐类型标签。
3. `NoteBundleMetadataDatabase` 归 822 Room 清单面。

## 后果

`data/note/ops` 层闭合；同步失败合约有类型化锚点备查。
