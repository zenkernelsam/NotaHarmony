# ADR-0330：资料库搜索生命周期绑定

Status: Accepted - Phase 353（2026-08-24）

## Context

LibraryPage 搜索输入使用 180ms debounce。此前定时器回调没有捕获 lifecycle generation；页面销毁后迟到回调
仍可启动 ViewModel 查询，查询失败可向已离开页面弹搜索失败提示。

## Decision

- 定时器触发时先捕获当前 lifecycle generation，并要求 pageActive、lifecycle、request generation 和搜索文本一致。
- `isCurrentNotesRequest()` 增加可选 lifecycle generation 参数；搜索成功与失败续体必须使用触发时的完整身份。
- 过期回调不发起查询；过期结果不发布 notes/loading，也不显示 toast。
- 请求代数、ViewModel 身份、查询文本和 folder 身份等既有去重契约保持不变。

## Consequences

已销毁资料库实例不能被 debounce 回调或迟到查询结果打扰。durable 笔记数据保持权威。
真实设备连续输入、快速返回和长查询失败矩阵继续独立开放。
