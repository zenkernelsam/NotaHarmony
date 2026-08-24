# ADR-0363：笔记加载销毁绑定

Status: Accepted - Phase 386（2026-08-25）

## Context

`NotePage.loadPages()` 在 `getNote()` 返回后只比较 `loadGeneration`，未检查 `editorDisposed`。页面销毁后的迟到
成功仍可写入 `noteTitle` 并继续读取和发布页面列表；同函数后续门禁已联合检查销毁与代次，失败路径也已联合检查。

## Decision

- `getNote()` 返回后立即使用 `editorDisposed || loadGeneration !== pageLoadGeneration` 联合门禁。
- 陈旧或销毁态不发布标题、不继续加载页面、不触发背景刷新或录音加载。
- 活动页首次加载、换代重载语义以及失败路径与 finally 清理保持不变。

## Consequences

销毁后的旧编辑页不会再接收迟到的笔记标题和页面数据。真实路由关闭时序仍需后续设备级验收；本决策不启动模拟
器、虚拟机、真机或 Hypium。