# Phase 132 修复总结：原版 Paste 叶 CREATE 共享 revision batch

## 问题与原版依据

- 原版 `lg2.g()` 递归取得选中 Group 的叶后代，再由 `u5j.c()` 进入模型复制路径；`lg2.e()` 从实际
  CREATE_GROUP operations 恢复顶层选择。完整 Paste 必须是一个复合模型提交，不能让每个叶实体
  各自推进页面 revision。
- Harmony 的 CREATE_BLOCK 与 INSERT_TEXT 已支持共享 `OriginalPageMutationBatch`，但 CREATE_INK
  和 CREATE_SHAPE 仍各自立即 flush。同页混合粘贴会形成多个 revision，也无法让后续 NCP1 页面
  mutation 精确对应一次提交。

## 已完成修复

- CREATE_INK 增加 typed-payload batch 入口；可见 Ink 快照写统一的 `old + 1` revision，登记 Ink
  搜索失效，外部 batch 模式不自行更新页面行。
- CREATE_SHAPE 增加仅接受 type 18 的 typed-payload batch 入口；共享 batch 模式登记非文本 Block，
  独立 reducer 路径仍自行 flush，旧入站行为不变。
- 同一 batch 可合并 Ink、Text 和普通 Block 标志；页面 revision 最终以旧值 CAS 一次，搜索索引按
  合并后的实际类型失效。隐藏 CREATE 继续只落 tombstone，不伪造页面内容变化。
- 扩展 ArkTS fixture，以同页 Ink、Text Block 和 Shape Block 三次登记断言只有一次 update；新增
  ADR-0109 和 `d02-original-create-leaf-revision-batch.mjs`。

## 验证与后续

- 专项 replay 输出为
  `originalCreateLeafRevisionBatch=ink-shape-block-text-shared-cas-single-revision-search-invalidation`。
- 全量桌面 replay 为 `TOTAL=118 FAILED=0`，`git diff --check` 通过；执行 `hvigorw clean` 后严格
  串行构建 `note@ohosTest` 与 `note@default`，两套 HAP 均为 `BUILD SUCCESSFUL`，只有项目既有
  deprecated/exception-handling warning。
- 未启动模拟器、虚拟机、真机或 Hypium。
- 下一阶段在 `StrokePersistence` 新增真正的一次事务生产 API：事务内分配所有 identity、应用全部叶
  CREATE、一次 flush、bottom-up CREATE_GROUP，并写一条 NCP1 history companion；任一步失败整体
  rollback。
