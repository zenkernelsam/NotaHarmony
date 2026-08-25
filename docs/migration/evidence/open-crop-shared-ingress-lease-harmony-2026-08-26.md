# Harmony 证据 — Phase 465 已打开裁剪共享租约修复

## 变更位置

- `note/src/main/ets/ui/components/ImageCropOverlay.ets`
  - 新增 `photoImportLeaseActive` 与 `controlsEnabled` 派生门禁。
  - 关闭、重置、确认三个控件绑定该门禁。
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
  - 裁剪层传入 `this.photoImportBusy`。
  - `onMove/onClose/onReset/onConfirm` 先拒绝共享导入租约，再拒绝历史租约。

## 静态验证

- 新增焦点 Replay：
  `docs/migration/replays/d02-open-crop-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=10 FAILED=0`。
- 相邻 `d02-image-crop-shared-lease-bound.mjs` 与本地图片裁剪 outbound Replay 均通过。
- ArkTS 检查 `ImageCropOverlay.ets` 无诊断；`NoteCanvasView.ets` 仅保留既有
  unused/deprecation 信息。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium。验证均为静态源绑定、本地 Replay 和构建检查；
`T-042` 继续保持 Goal 最后任务。
