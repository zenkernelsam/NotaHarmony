# ADR-0365：普通粘贴保存反馈销毁绑定

Status: Accepted - Phase 388（2026-08-25）

## Context

普通粘贴把元素入队后通过 deferred flush 清理 saveFailed。成功续体只比较 generation 与 pageId；失败续体虽然
检查 loaded、loading、failed 和 currentPage，但缺少 lifecycleActive。编辑器销毁后这些字段可能仍保持旧值，
迟到失败会调用 reportSaveFailure() 并触达旧 UI。

## Decision

- 成功与失败两个 deferred 续体统一复用 isHistoryPageContextCurrent(generation, pageId)。
- 该门禁包含 lifecycleActive、generation、loadedPageId、currentPage、loaded、dataLoading 和 dataLoadFailed。
- 陈旧态继续保留 durable hilog，但不发布 toast，也不清除旧页的 saveFailed 状态。
- 同步入队失败、剪贴板提交、页面状态发布、撤销历史和渲染路径保持不变。

## Consequences

销毁后的迟到粘贴保存结果不再驱动旧画布反馈；活动页的成功清理与失败提示语义不变。真实关闭竞态仍需后续设备
级验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
