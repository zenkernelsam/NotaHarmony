# ADR-0966 — sxa Context 持有器 + hl3 读侧

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `sxa` = **Context-only 占位**（无方法——Kotlin
  扩展使用）——nr1 的系统服务检查宿主。
- `hl3` 只有 DraftNote 读/删侧（`DELETE...IN`
  批量）；INSERT 绑定器在别处（wp1 系）。
- `cx6` = 检查/取值 iface。

## Harmony 决策

`sxa`→getContext()+NetworkKit 服务检测；DraftNote
读删写分离保留。

## Parity 状态

等价（结构推断标注）。

## 验证

- `d02-sxa-context.mjs`：10/10 通过。
