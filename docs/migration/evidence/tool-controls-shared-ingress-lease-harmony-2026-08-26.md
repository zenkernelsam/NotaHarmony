# Harmony 证据 — Phase 470 工具控制共享租约修复

## 变更位置

- `note/src/main/ets/ui/components/ColorPicker.ets`
  - 新增 `photoImportLeaseActive`；十二个色块统一禁用。
- `note/src/main/ets/ui/components/WidthSlider.ets`
  - 新增 `photoImportLeaseActive`；滑杆禁用。
- `note/src/main/ets/ui/editor/EditorToolbar.ets`
  - 新增共享租约属性并传给两个已打开面板。
- `note/src/main/ets/ui/editor/NotePage.ets`
  - 把父页共享导入租约传给工具栏；既有选区颜色/宽度回调保留双层防御。

## 静态验证

- 新增焦点 Replay：
  `docs/migration/replays/d02-tool-controls-shared-ingress-lease-bound.mjs`
  输出 `TOTAL=9 FAILED=0`。
- 相邻历史工具栏、选区样式共享租约、编辑器工具状态回滚并发、失败销毁、本地墨迹/
  形状颜色宽度以及变宽 Hermite Replay 通过。
- ArkTS 检查四个目标文件无错误；仅 `NotePage.ets` 既有 unused 与 deprecated 信息。

## 运行边界

未启动模拟器、虚拟机、真机或 Hypium。验证均为静态源绑定、本地 Replay 和构建检查；
`T-042` 继续保持 Goal 最后任务。
