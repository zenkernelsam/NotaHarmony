# Phase 1343 证据 — op 应用器族 + 状态存储

来源：`data/Original{AddPathElements,ModifyInk,
ModifyPositions,TransientInteraction}Operation.ets`+
`Original{EntityVisibilityState,OutboundOperationRepair}.ets`
等。

## `OriginalAddPathElementsOperation` = 墨迹增量追加

```
apply(store, op):
  校验目标 ink 存在 → validateOperationIdentity
  decode InkPathAppend → applyPayload/applyTable
  身份冲突检测：
    'conflicts with persisted actual path'
    'conflicts with persisted estimated path'
    'partial persisted state'
```

→ `ADD_PATH_ELEMENTS` = 进行中笔画的**增量追加**（实时
同步中的笔画分段下发）—— 落 RdbStore + 身份冲突检测
（actual/estimated path、partial state）。

## op 应用器族

- `OriginalModifyInkOperation` —— 墨迹修改（颜色/线宽）。
- `OriginalModifyPositionsOperation` —— 元素位移。
- `OriginalTransientInteractionOperation` —— 瞬态交互
  op（如选区/拖拽的中间态，不持久化）。
- `OriginalEntityVisibilityState` —— 实体可见性状态。
- `OriginalOutboundOperationRepair` —— 出站 op 修复。

## Harmony 决策

op 应用器 = 逐 op 校验+冲突检测+RdbStore 落库 —
— 对照 `haa` op 应用语义；身份冲突显式报错（对照
`ops/synced` Corrupted/Consistency 异常）。

## 产出

- fixture `d02-op-appliers.mjs`（10 断言）。
- ADR-1285；中文报告。
