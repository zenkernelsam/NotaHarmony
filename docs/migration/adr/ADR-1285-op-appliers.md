# ADR-1285：op 应用器族

## 状态

已接受（Phase 1343）。

## 决策

op 应用器 = 逐 op 校验 + 身份冲突检测 + RdbStore 落库
—— 对照 `haa` op 应用语义。

## 理由

`OriginalAddPathElementsOperation`（`ADD_PATH_ELEMENTS`
增量笔画追加：decode `InkPathAppend`+目标 ink 校验+
actual/estimated path 冲突检测+partial-state 守卫）+
`ModifyInk`/`ModifyPositions`/`TransientInteraction`/
`EntityVisibilityState`/`OutboundOperationRepair` ——
冲突显式报错，对照 `ops/synced` Corrupted 异常。

## 后果

op 应用含身份冲突检测+部分状态守卫 —— CRDT 应用
正确性保真。
