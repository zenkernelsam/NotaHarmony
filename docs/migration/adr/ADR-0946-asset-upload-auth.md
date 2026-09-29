# ADR-0946 — `vqf` 资产直传 + `f8c` 鉴权 + `je3` DeviceId

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `vqf`：`@POST @Url` 动态地址 —— GCS 签名 URL
  直传；headers `content-md5` +
  `x-goog-content-length-range`；body `nwb`。
- `f8c`：`/google/sign-in`、`/microsoft/sign-in`
  （body `d8c`→`ryb<e8c>`）、`/auth/nonce`
  （→`ryb<a8c>`）。
- `je3` = `@fyc(with=qe3)` DeviceId{ttf}；
  `a()` = SecureRandom + RFC4122 v4 位修正。
- `ko.o`/`wqf.b` 均以 `je3.a` 为 deviceId。

## Harmony 决策

- vqf/f8c fail-closed（无服务器 + GMS 依赖）。
- DeviceId 平移 `util.generateRandomUUID`。

## Parity 状态

fail-closed（登录/资产上传）；DeviceId 等价。

## 验证

- `d02-asset-upload-auth.mjs`：14/14 通过。
