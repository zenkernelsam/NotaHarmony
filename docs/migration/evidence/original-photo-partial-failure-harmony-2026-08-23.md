# Phase 290 Harmony 多图照片部分失败证据（2026-08-23）

## 当前源码事实

- `startOriginalPhotoInsert()` 接收 `PhotoInsertOutcome`；`insertedCount < totalCount` 时显示
  `original_photo_insert_partial_failed`。
- `insertOriginalPhotos()` 捕获每张 `commitOriginalImageInsert()` 异常并 break；已成功结果继续构造
  final images/order 和一个 `ADD_ELEMENTS` action，先 `undoRedo.push()` 再返回 outcome。
- 第一张失败时 `results.length === 0`，抛出原有 commit failed 错误；外层显示
  `original_photo_insert_failed`，不会产生成功 action 或 UI 安装。
- 只有全部插入成功才把 `saveFailed` 清为 false；部分失败不清全局保存状态，也不调用
  `reportSaveFailure()`，避免 save toast 与 photo toast 双重反馈。
- 中英资源分别固定为 “Some photos couldn't be added” 与 “部分图片未能添加”。

## 原版对照

`tf9.java` 的列表校验仍是 all-or-nothing，且发生在 URI ingress 前；Harmony
`validateOriginalPhotoSelection()` 已保留该入口语义。反编译证据没有展示单张持久化中途失败的补偿分支，
因此本阶段不声称复现跨图 rollback。

## 静态验证

新增 `d02-original-photo-partial-failure.mjs` 覆盖 7 项契约；Phase 289 历史 metadata Replay 与相邻
photo picker/ingress/persistence Replays 继续通过。真实设备失败注入未执行。
