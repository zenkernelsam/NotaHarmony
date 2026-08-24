# ADR-0351：通用保存入队失败上下文绑定

Status: Accepted - Phase 374（2026-08-24）

## Context

`persist()` 的 `queueSaveElements()` 同步失败无条件调用 `reportSaveFailure`；同一函数的迟到 flush 失败已用
`isHistoryPageContextCurrent` 门禁。销毁或换代后的同步异常仍可向旧 Canvas 弹保存失败。

## Decision

- 同步入队失败复用现有历史页上下文谓词，联合校验活动页、同代、页面身份与加载健康。
- 陈旧/销毁续体不触达 UI；活动页提示语义不变。
- 迟到 flush 门禁和持久化语义不变。

## Consequences

旧 NoteCanvasView 不再因迟到的通用保存入队失败而弹提示。真实设备快速切页矩阵仍属后续验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
