# ADR-0457: 工具颜色与粗细纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

`ColorPickerView` 与 `WidthSlider` 已通过 `.enabled(!photoImportLeaseActive)` 在租约激活时
禁用控件；但颜色格点击和粗细滑杆变更仍是直接回调。若租约信号在交互后生效，回调仍可能调用
选中墨色、选中粗细或活动笔刷状态更新。

## 决策

两个控件的直接回调先拒绝 `photoImportLeaseActive`，再执行原有分支。响应式禁用保留为第一层；
组件内回调拒绝作为第二层。父页 `onSelectionColor()` / `onSelectionWidth()` 的页面操作、历史
挂起和结构租约防线继续兜底；普通笔刷颜色与粗细持久化语义不变。

## 结果

共享照片导入窗口内不会因竞态改写工具颜色或粗细。正常选色、选宽、选中样式编辑和默认工具
行为保持不变。专项 Replay 锁定两项新防线。
全量 Desktop Replay 421/421（35.912 秒）；clean 3.544 秒、ohosTest HAP 11.218 秒、
default HAP 34.746 秒静态构建成功。
未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
