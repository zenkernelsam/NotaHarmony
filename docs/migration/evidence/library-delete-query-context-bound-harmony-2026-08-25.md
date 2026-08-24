# Phase 410 Harmony 证据：资料库删除替换读取查询绑定

## 缺陷证据

- Phase 409 后的 `deleteNote()` replacement read 只捕获 `this.currentFolderId`，直接选择 `getAllNotes()` 或 `getNotesByFolder()`。
- `loadNotes(query)` 是唯一携带搜索词的入口；原类没有保存 active query。因此搜索读取 await 期间的删除会把未过滤快照发布到 UI。

## Harmony 变更

- 新增私有 `activeQuery`，`loadNotes()` 进入时同步保存本次权威查询。
- 删除接管 in-flight 权威读取时读取 `activeQuery`，并复用与 `loadNotes()` 相同的 search/folder 分支。
- replacement read 继续捕获 mutationGeneration，stale 或被更新 mutation 作废时重试，guarded finally 清理 loading。

## 本地实测

- ArkTS 检查：`LibraryViewModel.ets` 与 `LibraryViewModel.test.ets` 无错误。
- 加强专项 Replay 至 6/6，新增断言 replacement 必须保留 search 与 folder 上下文。
- ArkTS fixture 新增搜索 `alp` 中删除 `Alpha` 的场景：replacement 不返回未过滤 `Beta`，loading 清除且 durable delete 保持一次。
- 相邻 `d02-library-note-mutation-order.mjs` 保持 8/8；相邻 `d02-library-mutation-lifecycle.mjs` 保持 10/10。

## 边界

本阶段只处理资料库删除 replacement read 的查询上下文；真实设备并发、低内存与数据库故障注入仍未验证。未启动模拟器、虚拟机、真机或 Hypium。
