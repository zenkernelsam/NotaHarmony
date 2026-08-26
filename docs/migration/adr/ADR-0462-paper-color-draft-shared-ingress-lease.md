# ADR-0462: 纸色草稿入口纳入共享照片导入租约

日期：2026-08-26

## 状态

Accepted

## 背景

页面设置面板的尺寸、自定义色开关和方向已有共享导入防线；但 legacy 色格选择、自定义色展开
及三个 HSV 滑杆更新仍缺少组件内第二层拒绝。租约切换竞态中，晚到事件可先改写纸张颜色草稿。

## 决策

`selectLegacyPaper()` 与 `activateCustomColor()` 的门禁加入 `photoImportLeaseActive`；三个
HSV 更新函数在修改滑杆状态或生成 ARGB 前拒绝该租约。响应式禁用、无 alpha 语义、模板预览、
共享纸设置和默认模板页行为不变。

## 结果

共享照片导入窗口内，晚到的纸色交互不会再改写页面背景草稿。正常选色与自定义色编辑保持不变。
专项 Replay 锁定五项新防线。
全量 Desktop Replay 421/421（30.895 秒）；clean 3.248 秒、ohosTest HAP 9.792 秒、default HAP
29.478 秒静态构建成功。
未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
