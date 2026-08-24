# ADR-0350：普通粘贴入队失败上下文绑定

Status: Accepted - Phase 373（2026-08-24）

## Context

普通剪贴板粘贴的 `queueSaveElements()` 同步失败无条件调用 `reportSaveFailure`；同一入口的迟到 flush 失败已经要求
健康页上下文。组件销毁或换代后的入队异常仍可向旧 Canvas 弹保存失败。

## Decision

- 入队失败先用现有 `isHistoryPageContextCurrent` 联合校验活动页、同代、页面身份与加载健康；陈旧/销毁续体直接返回。
- 活动页提示语义不变，不发布 UI/history/clipboard。
- 迟到 flush 门禁和 finally 清理契约不变。

## Consequences

旧 NoteCanvasView 不再因迟到的普通粘贴入队失败而弹提示。真实设备快速切页矩阵仍属后续验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
