# Harmony Evidence — 图片裁剪把手共享照片导入租约

日期：2026-08-26
阶段：Phase 486
结论：通过（静态验证）

## 代码证据

- `ImageCropOverlay.ets`
  - 把手 `PanGesture.onActionUpdate()` 先拒绝 `photoImportLeaseActive`，再读取手势偏移、计算
    增量并调用父页 `onMove()`。
  - 关闭、重置、确认按钮的 `.enabled(controlsEnabled)` 与父页共享/历史双层防线不变。
  - 拖动起点/结束/取消状态、选区角点、工具栏定位、确认事务和销毁清理不变。
- `NoteCanvasView` 继续显式传入共享导入租约，并在 `onMove()` 中先拒绝共享导入再拒绝历史。

## 静态验证

- 聚焦 Replay：
  `docs/migration/replays/d02-open-crop-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=11 FAILED=0`。
- 相邻 Replay：图片裁剪共享租约、本地图片裁剪出界通过。
- ArkTS：`ImageCropOverlay.ets` 无错误，仅既有警告与信息级提示。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （32.457 秒）。
- clean：3.446 秒；ohosTest HAP：9.929 秒；default HAP：30.383 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。

---

日期：2026-08-26
阶段：Phase 496
结论：通过（静态验证）

## 增量代码证据

- `ImageCropOverlay.ets`
  - 关闭、重置和确认按钮的组件内回调先检查 `controlsEnabled`，租约激活时拒绝转发。
  - `.enabled(controlsEnabled)` 响应式第一层、父页共享/历史双层防线和把手更新守卫保持不变。
  - 选区角点、工具栏定位、确认事务、撤销语义和销毁清理不变。

## 增量静态验证

- 聚焦 Replay：
  `docs/migration/replays/d02-open-crop-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=14 FAILED=0`。
- 相邻 Replay：图片裁剪共享租约与本地图片裁剪出界通过。
- ArkTS：`ImageCropOverlay.ets` 无错误，仅既有警告与信息级提示。
- 全量 Desktop Replay：`REPLAY_FILES=421 PASSED=421 FAILED_FILES=0`
  （35.720 秒）。
- clean：3.611 秒；ohosTest HAP：11.619 秒；default HAP：35.182 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
