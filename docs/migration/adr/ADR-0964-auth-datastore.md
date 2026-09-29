# ADR-0964 — xrf 鉴权 DataStore

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `xrf extends hq8` = Preferences DataStore：5 个
  `eua` 键（dataVersion/authToken/emailToDeviceIds/
  currentUserEmail/currentUserId）+ `prf`/`qrf`
  迁移序列化器链。
- `g`/`h`/`i`/`j` = `pce` 懒 key→Flow getter。

## Harmony 决策

- `@ohos.data.preferences` 等价；**token/用户身份
  加密存**（AssetStore）；
- 鉴权仍 fail-closed（OAuth）。

## Parity 状态

存储等价（加密要求标注）；鉴权 fail-closed。

## 验证

- `d02-auth-datastore.mjs`：10/10 通过。
