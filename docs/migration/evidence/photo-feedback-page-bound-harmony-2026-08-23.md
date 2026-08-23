# 照片插入反馈页面绑定证据

证据时间：2026-08-23（Asia/Shanghai）

## 竞态

`startOriginalPhotoInsert()` 的 toast 位于 picker 选择、URI 导入和逐张 SQLite 提交之后。若用户在这些异步边界中
切页，旧页的 partial 或 whole-batch failure toast 会出现在新页；与 Phase 305/307 的页面状态绑定不一致。

## Phase 308 契约

1. 入口捕获发起页 `pageLoadGeneration` 与 `loadedPageId`；
2. partial toast 需要“仍在发起页 + insertedCount < totalCount”；
3. whole-batch failure toast 需要“仍在发起页”，异常继续写 hilog；
4. 跨页路径不弹旧页反馈，但仍释放 `photoImportBusy`；
5. 数据库结果、undo history、outcome 和 Phase 307 的 save-state 绑定保持不变。

## 边界

真实系统 picker 中断和跨页矩阵需要设备验收；本阶段只做静态契约、Desktop Replay 和双 HAP 打包。未启动模拟器、
虚拟机、真机或 Hypium。
