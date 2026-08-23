# Phase 325 修复总结：Library 笔记创建删除生命周期绑定

日期：2026-08-23（Asia/Shanghai）

## 缺陷与修复

- `deleteNoteAndRefresh()` 和 `createAndOpen()` 在 await 后没有生命周期守卫；用户离开 Library 后，迟到删除可发布
  快照并调度缩略图，迟到创建可发布快照、弹失败 toast，甚至从已销毁页面导航打开新笔记。
- 两个入口捕获 `lifecycleGeneration`；await 后要求同代数、`pageActive` 和 viewModel 一致，才写状态/弹 UI/导航。
  守卫路径同步重置 busy 标志。过期完成只保留 durable 数据。

## 产物与验证

- ADR：`docs/migration/adr/ADR-0302-library-note-create-delete-lifecycle-bound.md`
- Evidence：`docs/migration/evidence/library-note-create-delete-lifecycle-bound-harmony-2026-08-23.md`
- Replay：`docs/migration/replays/d02-library-note-create-delete-lifecycle-bound.mjs`（4/4 通过）。
- 全量 Desktop Replay：`REPLAY_FILES=292 PASSED=292 FAILED_FILES=0`。静态双 HAP 跳过签名并通过：
  `note@default` 12.702 秒，`note@ohosTest` 8.852 秒。
- 未启动模拟器、虚拟机、真机或 Hypium；真实离开后完成矩阵保留设备验收。
