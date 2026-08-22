# ADR-0272: Read Pasteboard Permission Gateway

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

HarmonyOS SDK 声明 `SystemPasteboard.getData()` 自 API 12 需要 `ohos.permission.READ_PASTEBOARD`，
拒绝时抛出 BusinessError 201。Phase 291 只依赖异常路径，没有声明权限，也没有显式请求与降级语义。

## Decision

在模块清单声明 user-grant `READ_PASTEBOARD`，提供本地化 reason；剪贴板图片 Paste 在读取系统数据前调用
`abilityAccessCtrl.requestPermissionsFromUser()`。生产 gateway 严格要求返回数组恰好包含该权限且
authResult 为 `PERMISSION_GRANTED`；未授权或请求异常都进入既有“无法添加图片”反馈，不读取 Pasteboard。
测试通过 requester 注入边界验证请求名、授权、拒绝和异常。

## Consequences

- 静态链路满足 SDK permission 契约并避免未授权读取；
- 系统弹窗时机、用户拒绝后再请求策略和厂商兼容行为仍需真实设备验收；
- `T-042` 不受影响，继续保留为 Goal 最后一项。
