# 修复总结 — Phase 495 Undo/Redo 按钮共享租约修复

## 问题

工具栏 Undo/Redo 按钮已有响应式禁用，父页回调与画布历史执行也有防线；但组件内点击直接转发，
缺少与其他直改入口一致的组件内第二层拒绝。

## 修复

两个按钮回调先拒绝 `photoImportLeaseActive`，再转发原有父页回调。可用性条件、页面操作、
历史挂起、结构状态和历史执行顺序不变。

## 影响与验证

- 新增 ADR-0467，并在既有 Harmony evidence 文件追加本阶段增量段。
- 扩展历史工具栏共享租约专项 Replay 锁定两项新防线，当前 `TOTAL=12 FAILED=0`。
- ArkTS 目标无错误，仅既有警告与信息级提示。
- 相邻选中样式与本地墨迹样式 Replay 通过。
- 全量 Desktop Replay `REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （32.864 秒）；clean 3.379 秒、ohosTest HAP 10.370 秒、default HAP 30.714 秒均静态构建成功。
- 未启动模拟器、虚拟机、真机或 Hypium；T-042 继续保留为 Goal 最后任务。
