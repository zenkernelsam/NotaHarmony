# ADR-0364：资料库初始化渲染器身份绑定

Status: Accepted - Phase 387（2026-08-25）

## Context

`LibraryPage.initData()` 在 `getPreferences()` 后只检查 pageActive 与 lifecycleGeneration，未比较 renderer 身份。
页面销毁会替换 `thumbRenderer`；迟到续体可继续初始化数据库并创建、发布新 repositories。后续门禁已包含
renderer 比较，但该续体遗漏了同一条件。

## Decision

- 在 try 开头捕获当前 renderer，供偏好读取后的门禁使用。
- 偏好读取返回后必须同时满足 pageActive、lifecycleGeneration 与 renderer 身份，才允许初始化数据库。
- 捕获的 renderer 初始化后保留既有身份门禁；活动页初始化、换代重载和失败发布语义不变。

## Consequences

销毁或换代后的旧初始化任务不会再使用被退役的 renderer 初始化数据库，也不会发布新仓库状态。真实快速关闭
时序仍需后续设备级验收；本决策不启动模拟器、虚拟机、真机或 Hypium。