# Phase 324 修复总结：Library 变更生命周期绑定

日期：2026-08-23（Asia/Shanghai）

## 缺陷与修复

- 文件夹创建/重命名/删除/排序和笔记移动在 SQLite await 后没有生命周期守卫；用户离开 Library 后，迟到成功仍会
  发布文件夹或笔记快照、重置当前文件夹选择、调度缩略图刷新，失败路径也可能对已销毁页面弹 toast。
- 四个入口现在捕获 `lifecycleGeneration`；持久化成功后要求同代数、`pageActive` 和相关 repo/viewModel 引用一致，
  才发布内存状态。过期成功只保留 durable 数据，跳过所有内存/UI 发布。

## 产物与验证

- ADR：`docs/migration/adr/ADR-0301-library-mutations-lifecycle-bound.md`
- Evidence：`docs/migration/evidence/library-mutations-lifecycle-bound-harmony-2026-08-23.md`
- Replay：`docs/migration/replays/d02-library-folder-mutations-lifecycle-bound.mjs`（5/5 通过）。
- 全量 Desktop Replay：`REPLAY_FILES=291 PASSED=291 FAILED_FILES=0`。静态双 HAP 跳过签名并通过：
  `note@default` 12.208 秒，`note@ohosTest` 8.188 秒。
- 未启动模拟器、虚拟机、真机或 Hypium；真实离开后完成矩阵保留设备验收。
