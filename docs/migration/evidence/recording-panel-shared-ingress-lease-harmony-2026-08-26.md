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

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium。所有验证均为静态源绑定、本地 Replay 和构建检查；
`T-042` 继续保持 Goal 最后任务。
