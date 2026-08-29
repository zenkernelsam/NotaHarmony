# ADR-0495：页面设置颜色事件忙碌边界

日期：2026-08-26

## 状态

Accepted

## 背景

`PageSettingsPanel` 的自定义颜色 H/S/V 滑杆事件此前只检查共享照片导入租约。忙碌、共享纸库设置加载或间距保存期间的晚到事件仍可能改写 HSV 草稿，并调用 `stageCustomColor()`。

## 决策

三个颜色通道更新方法统一在限幅和暂存前拒绝 `busy || photoImportLeaseActive || sharedBusy || spacingSaveBusy`。响应式禁用与方法级门禁保持一致；尺寸、方向、模板、收藏、间距和正常交互语义不变。

## 结果

颜色事件与页面设置其余入口共享同一 fail-closed 忙态边界。专项 Replay 锁定三处组合守卫，并禁止旧的“仅共享租约”模式。
