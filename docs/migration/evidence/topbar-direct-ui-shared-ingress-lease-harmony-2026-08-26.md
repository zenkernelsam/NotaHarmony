# Harmony Evidence — 顶栏直改共享照片导入租约

日期：2026-08-26
阶段：Phase 473
结论：通过（静态验证）

## 代码证据

- `NotePage.ets`
  - 非编辑态标题点击先拒绝 `photoImportLeaseActive`，再保留加载失败与加载中防御。
  - 编辑态 `TextInput.onChange` 先拒绝该租约，再截断并写入 `titleDraft`。
  - 录音按钮启用条件叠加该租约；回调先拒绝租约，再执行原有开/关逻辑。
  - 标题串行队列不变：未变更标题幂等发布，变更标题继续被 `commitTitle` 原有租约防御
    拒绝；`closeRecordings` 原语义不变。
- 新增专项 Replay 锁定标题入口、草稿输入、录音开关、既有提交防线与关闭语义。

## 静态验证

- ArkTS：`note/src/main/ets/ui/editor/NotePage.ets` 无错误；仅既有未使用符号警告和
  弃用 API 信息级提示。
- 聚焦 Replay：
  `docs/migration/replays/d02-topbar-direct-ui-mutations-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=5 FAILED=0`。
- 相邻 Replay：标题共享租约（10/10）与录音面板共享租约（12/12）通过。
- 全量 Desktop Replay：`REPLAY_FILES=414 PASSED=414 FAILED_FILES=0`
  （30.415 秒）。
- clean：3.456 秒；ohosTest HAP：9.835 秒；default HAP：29.402 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
