# ADR-0461: 公式覆盖层动作纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

`MathEditorOverlay` 已按忙碌与共享导入租约禁用输入框和按钮；父页 `onDraftChange()` /
`onCancel()` / `onConfirm()` 也先拒绝共享导入与历史租约。但三个组件内直接转发可在租约切换
竞态中先发布草稿或触发取消/确认。

## 决策

公式输入 `onChange()`、取消 `onClick()` 和完成 `onClick()` 先拒绝 `photoImportLeaseActive`，
再调用原有父页回调。响应式可用性、草稿校验、预览状态、插入事务、历史语义和失败提示不变。

## 结果

共享照片导入窗口内，晚到的公式编辑事件不会再改写草稿或触发提交。正常公式创建行为保持不变。
专项 Replay 锁定三项新防线。
全量 Desktop Replay 421/421（29.975 秒）；clean 3.211 秒、ohosTest HAP 9.951 秒、default HAP
29.523 秒静态构建成功。
未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
