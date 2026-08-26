# ADR-0463: 选中样式按钮纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

`SelectionStyleButton` 已在共享导入租约激活时响应式禁用；父页 `onSelectionStyle()` 与画布
信号消费也拒绝共享导入及历史/结构租约。但按钮点击仍是组件内直接转发边界，租约切换竞态中可
先发布样式变更信号。

## 决策

选中样式按钮回调先拒绝 `photoImportLeaseActive`，再调用原有 `onSelectionStyle()`。可用性
条件、Taper 变量样式门禁、父页四层防线、信号消费和墨迹修改事务不变。

## 结果

共享照片导入窗口内，晚到的样式点击不会再发布选中墨迹变更。正常选中样式切换保持不变。专项
Replay 锁定组件内新防线。
全量 Desktop Replay 421/421（32.380 秒）；clean 3.258 秒、ohosTest HAP 10.489 秒、default HAP
31.526 秒静态构建成功。
未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
