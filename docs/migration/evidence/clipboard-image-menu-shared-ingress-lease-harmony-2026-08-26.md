# Harmony Evidence — 剪贴板图片菜单共享照片导入租约

日期：2026-08-26
阶段：Phase 477
结论：通过（静态验证）

## 代码证据

- `NoteCanvasView.ets`
  - 画布长按菜单仍绑定 `ClipboardPasteContextMenu`，保留原生长按锚点交互。
  - “粘贴图片”项点击后先拒绝 `photoImportBusy`，再调用 `startOriginalClipboardImagePaste()`。
  - 菜单可见性、`canUseOriginalClipboardImage()`、权限申请、页面上下文校验、插入事务和
    失败反馈不变。
- 新增专项 Replay 锁定菜单项守卫与上下文菜单绑定；既有剪贴板图片导入 Replay 保持通过。

## 静态验证

- ArkTS：`TextBlockOverlay.ets` 无诊断；`NoteCanvasView.ets` 无错误，仅既有未使用符号警告和
  弃用 API 信息级提示。检查前发现该文件存在孤立 CR 字节导致 LSP 接口漂移，已按 Git HEAD
  规范化为 LF，内容哈希恢复为 `91c530d25367f4ee6c0d4dd09ee09403fb4b5647`。
- 聚焦 Replay：
  `docs/migration/replays/d02-clipboard-image-menu-shared-ingress-guard.mjs`
  输出 `TOTAL=3 FAILED=0`。
- 相邻 Replay：原版剪贴板图片导入 29/29、画布触摸共享租约 11/11、文本提交共享租约 7/7 通过。
- 全量 Desktop Replay：`REPLAY_FILES=418 PASSED=418 FAILED_FILES=0`
  （30.295 秒）。
- clean：3.205 秒；ohosTest HAP：9.755 秒；default HAP：30.892 秒。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium；未清理既有临时产物；T-042 保持 Goal 最后任务。
