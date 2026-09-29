# Phase 1119 证据 — core/ 命名包异常谱系 + 包图

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
（`com/gingerlabs/notability/core/` 未混淆，Kotlin `@Metadata` 完整）

## `core/network/` 异常

- `HttpStatusException extends IOException` = `{int I code,
  String J, K}` —— HTTP 错误码 + 描述。
- `NoConnectivityException extends IOException` =
  `"No network connectivity"`。
- `NotAuthenticatedException` —— 401/未认证。

## `core/model/CopyPasteException extends Exception` = sealed 5 子类

`@Metadata` d2 枚举子类：
- `MissingPosition` —— 粘贴缺位置锚。
- `IncompatibleContent` —— 内容类型不兼容。
- `Consistency` —— 一致性违例。
- `InvalidArguments` —— 参数非法。
- `ConcurrentPaste` —— 并发粘贴冲突（data object 单例）。

## `core/` 包图（未混淆分层）

`analytics` `common(memory)` `flatbuffers` `glmath` `model`
`network` `retrofit` `user`（`UserDataStoreInitializer`）。

## 语义锚

- 网络错误三分类：HttpStatus(code)/NoConnectivity/NotAuth。
- 复制粘贴异常 = 5 变体 sealed（缺锚/不兼容/一致性/参数/并发）。

## Harmony 决策

- 网络异常 → Harmony `BusinessError`/`Error` 码映射
  （HttpStatus code / connectivity / auth 三类）。
- CopyPasteException → ArkTS sealed error union 5 变体。

## 产出

- fixture `d02-exception-taxonomy.mjs`（10 断言）。
- ADR-1063；中文报告。
