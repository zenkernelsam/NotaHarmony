# Harmony Evidence — 工具与笔刷样式按钮共享照片导入租约

日期：2026-08-26
阶段：Phase 479
结论：通过（静态验证）

## 代码证据

- `EditorToolbar.ets`
  - `ToolButton` 启用条件在 `toolStateLoading` 外叠加 `photoImportLeaseActive`。
  - `StyleButton` 同样叠加该租约。
  - 两者原回调先拒绝租约再修改 ViewModel；紧凑菜单、选区样式和历史路径不变。
- 新增专项 Replay 锁定两处一致化绑定与两项回调守卫。
- 相邻直改 Replay 更新为同时锁定旧加载门禁已被租约增强后的新绑定。

## 静态验证

- ArkTS：`note/src/main/ets/ui/editor/EditorToolbar.ets` 无诊断。
- 聚焦 Replay：
  `docs/migration/replays/d02-toolbar-builders-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=4 FAILED=0`。
- 相邻 Replay：工具栏直改更新后 11/11、按钮一致化 4/4 通过。
- 全量 Desktop Replay：`REPLAY_FILES=420 PASSED=420 FAILED_FILES=0`
  （28.924 秒）。
- clean：3.323 秒；ohosTest HAP：9.966 秒；default HAP：29.657 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
