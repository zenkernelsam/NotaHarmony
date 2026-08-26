# Harmony Evidence — 录音面板关闭共享照片导入租约

日期：2026-08-26
阶段：Phase 478
结论：通过（静态验证）

## 代码证据

- `NotePage.ets`
  - `RecordingPanel.onClose` 先拒绝 `photoImportLeaseActive`，再拒绝 `pageStructureLeaseActive`，
    然后调用原有关闭方法。
  - `closeRecordings()` 仍仅将 `showRecordings` 置为 false，不触碰录音控制器或会话生命周期。
  - 顶栏录音开关、面板控件回调和退出编辑器收尾逻辑不变。
- 新增专项 Replay 锁定关闭守卫、关闭语义和租约属性传递。
- 相邻 `d02-recording-panel-shared-ingress-lease-bound.mjs` 扩展为十项回调防线。

## 静态验证

- ArkTS：`note/src/main/ets/ui/editor/NotePage.ets` 无错误；仅既有未使用符号警告和弃用 API
  信息级提示。
- 聚焦 Replay：
  `docs/migration/replays/d02-recording-close-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=3 FAILED=0`。
- 相邻 Replay：录音面板共享租约 13/13、顶栏直改 5/5、录音会话 UI 与关闭生命周期通过。
- 全量 Desktop Replay：`REPLAY_FILES=419 PASSED=419 FAILED_FILES=0`
  （28.872 秒）。
- clean：3.189 秒；ohosTest HAP：9.898 秒；default HAP：29.422 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
