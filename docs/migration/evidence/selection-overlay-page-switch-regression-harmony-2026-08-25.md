# Harmony 证据：临时编辑器恢复与页面切换回归

日期：2026-08-25
范围：`note/src/main/ets/ui/editor/NoteCanvasView.ets`

## 回归证据

Phase 420 后源码顺序：

1. 页面设置变化触发 `onPageChange()`。
2. 该函数首先调用 `cancelImageCrop()` 和 `cancelMathEditing()`。
3. 随后才启动 `switchPageData()`。
4. 目标页数据加载且上下文有效后，才执行 `selectionTool.deselect()` 和 `selectionVisible = false`。

在步骤 2 时，SelectionTool 中的旧选区尚未清空。Phase 420 的取消路径在 `updateSelectionOverlay()` 后
无条件设置 `selectionVisible = true`，因此旧浮层会在新页开始加载前复活。若异步加载失败或上下文变化，
该显示状态可能跨越页边界残留。

图片裁剪取消还有第二个风险：它通过 session 里的 `imageId` 重装选择。若当前页已改变但旧 image ID 仍在缓存中，
无条件显示会把上一页对象当作当前页选择。

## 修复证据

移除三个取消/导航分离路径中的显式 `selectionVisible = true`：

| 路径 | 行为 |
| --- | --- |
| Math 导航分离 | 只调用 overlay helper；空态隐藏、非空态由 helper 显示 |
| Math 取消 | 同上 |
| 图片裁剪取消 | 重装 IDs 后只调用 overlay helper 和 nullable Ink reset |

Math 确认投影和图片裁剪确认保留显式 true，因为二者都在当前页上下文校验后重新安装本次操作产生的 IDs，
没有 Phase 420 要解决的隐藏恢复缺口以外的跨页窗口。

## Replay 断言

聚焦 Replay 新增：

- Math 导航分离/取消在 refresh 后遇到的第一条可见性写入必须是 helper 的 false，不得直接强制 true。
- 图片裁剪取消方法体内不得出现 `selectionVisible = false` 强制显示（即移除后的反向检查）。
- 模拟页面切换后的 stale selection 只刷新 helper 并保持隐藏。
- `onPageChange()` 必须先关闭图片裁剪和 Math 编辑，再启动页数据切换。

验证结果记录于阶段 Report。
