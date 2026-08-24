# Phase 409 Harmony 证据：资料库删除与权威读取生命周期绑定

## 代码证据

- `LibraryViewModel.loadNotes()` 先捕获 `mutationGeneration`，读取返回后若 mutation 已推进则重试，避免提交后快照被旧结果覆盖。
- `createNote()` 在同一 mutation chain 提交后推进 `mutationGeneration`，因此旧读取会重试。
- `deleteNote()` 原实现只调用 `removeVisibleNote()` 推进 mutation generation，没有处理自身仍在进行中的 `loadNotes()`；该读取已在 await 边界捕获旧 generation，最终可越过检查并复位 `isLoading`。

## Harmony 变更

- `deleteNote()` 的 committed continuation 现在检测 `isLoading`。
- 需要接管时递增 `loadGeneration`，按当前 folder 执行替换读取，并保留 stale read 与后续 mutation 的重试门禁。
- 替换读取失败只记录权威读取错误并抛出；durable 删除和可见列表投影已经完成。
- 只有最新且未作废的替换结果才发布；guarded finally 负责清除 loading。

## 本地实测

- 新增专项 Replay：`D02_LIBRARY_DELETE_LOADING_BOUND_OK TOTAL=5 FAILED=0`。
- ArkTS fixture 新增“删除落在 in-flight 权威读取期间”场景，断言删除后立即清除 loading 且旧读取不能恢复已删卡片。
- 相邻 `d02-library-note-mutation-order.mjs` 保持 8/8。
- 相邻 `d02-library-mutation-lifecycle.mjs` 保持 10/10。

## 边界

本阶段只处理资料库笔记删除与权威读取的生命周期竞态；真实设备并发、低内存和数据库故障注入仍未验证。未启动模拟器、虚拟机、真机或 Hypium。
