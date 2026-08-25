# Harmony 证据 — Phase 467 粘贴共享租约修复

## 变更位置

- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
  - `canPasteClipboardNow()` 在历史租约前加入 `photoImportBusy`。
  - `pasteClipboard()` 先按序拒绝共享导入与历史租约，再保留原门禁。
  - 缩放加减与适配宽度按钮绑定 `!photoImportBusy`。

## 静态验证

- 新增焦点 Replay：
  `docs/migration/replays/d02-paste-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=10 FAILED=0`。
- 相邻选区菜单共享租约、选区工具栏上下文、视口范围和视口保存生命周期 Replay 通过。
- ArkTS 检查 `NoteCanvasView.ets` 无错误；仅既有 unused/deprecation 信息。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium。验证均为静态源绑定、本地 Replay 和构建检查；
`T-042` 继续保持 Goal 最后任务。
