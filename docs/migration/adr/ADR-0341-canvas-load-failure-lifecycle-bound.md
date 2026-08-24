# ADR-0341：画布加载失败生命周期绑定

Status: Accepted - Phase 364（2026-08-24）

## Context

`loadNoteData()` 的失败续体只检查触发时 `pageLoadGeneration`。NoteCanvasView 销毁时设置
`lifecycleActive=false` 但不递增该代数，因此初始加载期间的迟到异常仍可进入失败态：释放资源、清空元素、
重建空层，并向已销毁组件弹出加载失败提示。

## Decision

- 失败续体在通过代数门禁后、进入本地失败发布前检查 `lifecycleActive`。
- 销毁后的迟到失败不调用 `enterLoadFailureState()` 或 `reportLoadFailure()`。
- 同代 `finally` 继续把 `dataLoading=false` 作为权威清理；成功路径和页面切换路径不变。

## Consequences

旧 Canvas 不再因销毁后的加载异常重置 UI。真实设备快速进入/退出与数据库故障矩阵仍属后续验收；本决策
不启动模拟器、虚拟机、真机或 Hypium。
