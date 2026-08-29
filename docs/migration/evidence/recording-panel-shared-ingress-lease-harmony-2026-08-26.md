# Harmony 证据 — Phase 464 录音面板共享租约修复

## 变更位置

- `note/src/main/ets/ui/editor/RecordingPanel.ets`
  - 新增 `photoImportLeaseActive` 属性与 `controlsEnabled` 派生门禁。
  - seek、三档速度、开始/暂停/恢复/停止录制、播放、删除和撤销删除绑定该门禁。
- `note/src/main/ets/ui/editor/NotePage.ets`
  - 录音面板传入 `photoImportLeaseActive`。
  - 九个回调在调用业务方法前拒绝共享导入与结构租约。

## 静态验证

- 新增焦点 Replay：
  `docs/migration/replays/d02-recording-panel-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=12 FAILED=0`。
- 本地全量 Desktop Replay：405 个文件全部通过。
- ArkTS 检查两个目标文件无错误；仅保留既有 unused/deprecation 与 List 布局建议信息。

## Phase 503 增量（2026-08-26）

- 继续补审发现：顶部栏“录音”按钮虽有响应式禁用，且父页 `onClose()` 等回调已拒绝共享与结构
  租约；但直接点击仍可在租约切换竞态中置位 `showRecordings` 并打开面板。
- 顶部栏回调现在先拒绝 `photoImportLeaseActive`，再执行原有关闭或打开逻辑。按钮可用性、
  面板布局、十个动作回调、会话控制和销毁清理不变。
- 扩展既有录音面板共享租约 Replay 至 `TOTAL=24 FAILED=0`。

## Phase 518 增量（2026-08-26）

- 继续补审发现：`controlsEnabled` 只拒绝共享租约；录音列表 `loading` 时，晚到点击可基于旧快照转发
  播放、删除、撤销或会话控制。
- 派生门禁现在同时拒绝 `loading`。响应式禁用、十项动作回调、共享/结构租约检查和父页语义不变。
- 扩展既有录音面板共享租约 Replay 至 `TOTAL=25 FAILED=0`。

## Phase 524 增量（2026-08-29）

- Phase 518 只把 `loading` 加入 `controlsEnabled`；九个动作事件的组件回调仍只拒绝共享导入租约，
  晚到事件可在列表替换或时间线重建期间继续转发。
- seek、暂停、恢复、停止、开始、倍速、播放、删除和撤销删除统一先拒绝
  `photoImportLeaseActive || loading`。关闭回调保留租约-only 守卫，加载中仍可收起面板。
- 专项 Replay 扩展至 `TOTAL=29 FAILED=0`，锁定九处组合守卫、一处关闭语义以及加载/空闲模型。

- 验证补录：全量 Desktop Replay `421/421`（35.203 秒）；clean 7.567 秒、ohosTest HAP 12.544 秒、
  default HAP 30.794 秒均静态构建成功。ArkTS 仅既有 List 尺寸建议。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium。所有验证均为静态源绑定、本地 Replay 和构建检查；
`T-042` 继续保持 Goal 最后任务。
