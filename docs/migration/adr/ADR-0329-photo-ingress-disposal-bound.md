# ADR-0329：原版图片入口销毁绑定

Status: Accepted - Phase 352（2026-08-24）

## Context

NoteCanvasView 的相册图片插入和剪贴板图片粘贴跨越系统 picker、权限请求、剪贴板读取和持久化 await。
这些入口此前只比较页面 generation/pageId；编辑器销毁后的迟到续体仍可弹失败/部分失败 toast、改写剪贴板可用状态，
并把 photoImportBusy 留给下一个画布实例。

## Decision

- 新增 `isPhotoContextCurrent(generation, pageId)`，统一要求 lifecycleActive、页面加载代数和 loadedPageId 全部一致。
- 相册插入的 partial-failure 与 failure toast 只在当前上下文发布。
- 剪贴板探测结果、权限中断、导入后状态和失败 toast 都通过同一上下文门；过期续体不写 UI 状态。
- `finally` 继续复位当前实例的 photoImportBusy；durable 图片与历史保持权威。

## Consequences

已离开的编辑器不能被迟到图片入口打扰。durable 成功仍按 Phase 321 的 stale-page 语义保留历史；
真实设备 picker/permission/pasteboard 矩阵继续独立开放。
