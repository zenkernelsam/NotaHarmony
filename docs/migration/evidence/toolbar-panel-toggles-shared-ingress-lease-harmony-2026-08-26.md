# Harmony Evidence — 颜色与宽度面板开关共享照片导入租约

日期：2026-08-26  
阶段：Phase 472  
结论：通过（静态验证）

## 代码证据

- `EditorToolbar.ets`
  - 颜色开关 `.enabled()` 在既有上下文和加载门禁外叠加 `!photoImportLeaseActive`。
  - 宽度开关同样叠加共享导入租约。
  - 两个回调先拒绝共享导入租约，再保留原有互斥切换逻辑：
    - 打开颜色时关闭宽度；
    - 打开宽度时关闭颜色。
- 新增专项 Replay 锁定两处禁用、两项回调和两组互斥状态更新。

## 静态验证

- ArkTS：`note/src/main/ets/ui/editor/EditorToolbar.ets` 无诊断。
- 聚焦 Replay：
  `docs/migration/replays/d02-toolbar-panel-toggles-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=6 FAILED=0`。
- 全量 Desktop Replay：`REPLAY_FILES=413 PASSED=413 FAILED_FILES=0`
  （29.575 秒）。
- clean：3.232 秒；ohosTest HAP：9.031 秒；default HAP：51.067 秒。
- 相邻 Replay：工具控制共享租约、工具栏直改共享租约和历史工具栏共享租约全部通过。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
