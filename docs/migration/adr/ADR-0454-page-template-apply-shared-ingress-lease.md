# ADR-0454: 页面模板应用纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

Phase 476 已在共享导入期抑制页面设置弹窗并禁用尺寸、自定义色和方向入口；但已打开弹窗中的模板
预览点击会调用 `applyTemplate()`。该函数此前只检查页面设置 busy、共享纸加载和间距保存状态，
随后直接触发父页 `runPageOperation()`，可在导入收口窗口内排队 `NOTE_BACKGROUND` 持久化与历史。

## 决策

`applyTemplate()` 的第一层门禁加入 `photoImportLeaseActive`，租约激活时拒绝模板应用。父页
`runPageOperation()` 与 `applyNoteBackgroundSettings()` 的原有防线保留为第二层；尺寸草稿、
方向草稿、自定义色、收藏和间距语义不变。

## 结果

已打开的页面设置弹窗不会再于共享照片导入窗口内启动页面背景事务。正常模板选择行为不变。
专项 Replay 锁定新防线。
未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
