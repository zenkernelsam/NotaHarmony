# Harmony Evidence — 工具栏直改共享照片导入租约

日期：2026-08-26  
阶段：Phase 471  
结论：通过（静态验证）

## 代码证据

- `EditorToolbar.ets` 新增共享导入租约消费点：
  - 紧凑“...”更多按钮禁用；
  - 四个紧凑工具菜单 action 先拒绝租约；
  - 普通 `ToolButton` 回调先拒绝租约再 `selectTool()`；
  - 普通 `StyleButton` 回调先拒绝租约再 `setBrushStyle()`；
  - 选区手绘/矩形切换禁用；
  - 选区样式按钮在既有 TAPER 规则外叠加租约禁用。

## 验证证据

- ArkTS：`note/src/main/ets/ui/editor/EditorToolbar.ets` 无诊断。
- 聚焦 Replay：`docs/migration/replays/d02-toolbar-direct-mutations-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=11 FAILED=0`。
- 全量 Desktop Replay：`REPLAY_FILES=412 PASSED=412 FAILED_FILES=0`
  （33.574 秒）。
- clean：3.630 秒；ohosTest HAP：10.525 秒；default HAP：58.301 秒。
- 相邻 Replay：工具控制、历史工具栏、选区样式和文本层共享租约全部通过。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
