# READ_PASTEBOARD 权限 SDK 证据与 Harmony 网关

证据时间：2026-08-23（Asia/Shanghai）
SDK 路径：DevEco Studio 默认 OpenHarmony SDK 类型声明。

## SDK 契约

- `@ohos.pasteboard.d.ts` 中 `SystemPasteboard.getData(): Promise<PasteData>` 的 since-12 重载标注：
  `@permission ohos.permission.READ_PASTEBOARD`；
- 同一方法抛出 `BusinessError 201 - Permission verification failed`；
- `permissions.d.ts` 将 `ohos.permission.READ_PASTEBOARD` 列入合法 Permissions 联合类型（since 11）；
- `@ohos.abilityAccessCtrl.d.ts` 提供 `requestPermissionsFromUser(context, [permission])`；
- `security/PermissionRequestResult.d.ts` 定义 `permissions` 与对应 `authResults`；
- `GrantStatus.PERMISSION_GRANTED = 0`。

## Harmony 差距

Phase 291 初版没有在 `module.json5` 声明该权限，也没有在读取前请求。静态 ArkTS Check 已经提示
`getData()` 需要权限，说明当前入口只可能依赖运行时失败，不构成可验收的生产链路。

## 生产网关

新增 `OriginalClipboardPermissionGateway`：

1. 使用 exact SDK 字符串 `ohos.permission.READ_PASTEBOARD`；
2. 通过注入边界隔离测试和生产 `requestPermissionsFromUser()`；
3. 要求 permissions 数组长度为 1、名称精确匹配、authResults 数组长度为 1 且值为 granted；
4. caller 在 `hasData()/getData()/getPrimaryPixelMap()` 之前 await 授权结果；
5. false 或异常由现有 catch 统一日志并 toast，不会继续读取剪贴板。
