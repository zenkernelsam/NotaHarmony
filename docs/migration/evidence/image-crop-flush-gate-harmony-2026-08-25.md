# Phase 423 图片裁剪 flush 门禁 Harmony 证据（2026-08-25）

## 源码边界

- `note/src/main/ets/ui/editor/NoteCanvasView.ets:693`：`flushCurrentPage()` 是当前页统一 flush 入口。
- `note/src/main/ets/ui/editor/NoteCanvasView.ets:701`：Math 与 image crop 门禁现在先于文本提交、
  queueSave、persistence flush 和 checkpoint。
- `note/src/main/ets/ui/editor/NoteCanvasView.ets:6423`：裁剪入口要求无 history busy 且未处于 crop 态。
- `note/src/main/ets/ui/editor/NoteCanvasView.ets:6447`、`:6459`、`:6509`、`:6521`：取消、几何刷新、
  正常出口均依赖同一 `imageCropVisible` / session 状态。
- `note/src/main/ets/ui/editor/NotePage.ets:1279` 起：删除流程捕获页身份后 await 当前页 flush；
  flush 返回 false 即不进入快照、prepare removal 或删除持久化。

## 原版证据

- Desktop 只读取证：`decompiled_1.0.3/sources/defpackage/lsc.java` 的 `ShowCropping` 将裁剪矩形和块
  绝对原点绑定当前选中元素，证明 crop 是页绑定的临时 UI 状态。
- 既有 Replay `d02-local-image-crop-outbound.mjs` 已约束 crop 出站编码、取消/确认与持久化路径；
  本阶段不改这些语义。

## 断言

- `docs/migration/replays/d02-flush-persist-page-health-bound.mjs` 新增：
  - Math/crop 联合门禁必须存在于 flush 函数体。
  - `return false` 必须早于文本提交分支。
  - 因此也早于 queueSave、persistence.flush 与 checkpoint 副作用。
- 全量 Desktop Replay 通过后补录统计。
