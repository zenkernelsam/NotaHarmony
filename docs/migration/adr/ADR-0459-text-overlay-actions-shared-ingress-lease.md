# ADR-0459: 文本覆盖层动作纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

`TextBlockOverlay` 已在共享导入租约激活时禁用文本框、完成和取消控件；`onDraftChange()` /
`onCancel()` 父回调与 `onTextCommit()` 也有共享导入及历史防线。但三个组件内回调仍会在租约
切换竞态中先修改草稿、发布预览或调用提交/取消。

## 决策

文本框 `onChange()`、完成 `onClick()` 和取消 `onClick()` 先拒绝 `photoImportLeaseActive`，
再执行原有草稿更新、父页提交或取消流程。响应式禁用、父页双层防线、文本测量预览、确认事务、
撤销语义和失败恢复不变。

## 结果

共享照片导入窗口内，晚到的文本输入或按钮事件不会再改写草稿或触发提交。正常文本编辑行为
保持不变。专项 Replay 锁定三项新防线。
全量 Desktop Replay 421/421（30.769 秒）；clean 3.251 秒、ohosTest HAP 9.892 秒、default HAP
30.076 秒静态构建成功。
未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
