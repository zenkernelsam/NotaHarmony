# Harmony 证据 — 照片导入与页面操作竞态

- `note/src/main/ets/ui/editor/NoteCanvasView.ets`：
  - `canStartOriginalPhotoInsert()` 检查 Canvas 内部 `photoImportBusy`，
    但该状态不暴露给父组件。
  - `startOriginalPhotoInsert()` 在 Picker/URI ingress 全程保持
    `photoImportBusy=true`，随后才设置 `historyBusy=true` 提交。
  - 剪贴板图片 `startOriginalClipboardImagePaste()` 使用同一长时 ingress
    状态，也必须在 `finally` 收口。
- `note/src/main/ets/ui/editor/NotePage.ets`：
  - 工具栏 `onInsertPhotos()` 原来无条件递增信号。
  - `runPageOperation()` 原来只拒绝 `pageOperationBusy`、`historyPending`
    与 `pageStructureLeaseActive`，无法感知 Canvas 正在导入。
  - 新增、删除、移动和背景设置都会经 `runPageOperation()` 改变页集合。
- 缺陷时序：点击插入照片进入长时 ingress 后，用户仍可触发页操作；页操作
  可能在提交前切换或删除页，照片提交只能依赖 stale-context 兜底，产生
  非确定性的部分成功/跳过路径。
- 修复事实：父页在发信号前取得共享 `photoImportLeaseActive`；
  `runPageOperation()`、`onRequestPage` 和页导航将其纳入门禁；Canvas 两个
  ingress 的 `finally` 回报 `onPhotoIngressFinished()`。既有
  generation/pageId 与 history metadata 防御继续保留。
- 验证：专项 Replay `d02-photo-import-page-operation-lease.mjs` 通过
  `TOTAL=12 FAILED=0`；ArkTS fixture
  `PhotoImportPageOperationLease.test.ets` 锁定互斥与重复信号边界。
