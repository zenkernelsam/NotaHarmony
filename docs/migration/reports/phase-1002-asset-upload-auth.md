# Phase 1002 报告 — 资产上传 + 鉴权 + DeviceId

## 范围

vqf GCS 直传、f8c 三鉴权端点、je3 DeviceId 值类。
纯审计。

## 原版发现

- `vqf`：`@POST @Url` —— 签名 URL 直传；
  `content-md5`/`x-goog-content-length-range` 头 =
  Google Cloud Storage 直传协议（资产不走 collab-api）。
- `f8c`：`/google/sign-in`、`/microsoft/sign-in`、
  `/auth/nonce`（ryb<a8c>）；登录体 `d8c` → `ryb<e8c>`。
- `je3` = DeviceId{ttf UUID}，`qe3` 序列化器，
  SecureRandom v4。
- 网络面至此全图：create/append/sync/bundle/
  thumbnails/asset-upload/auth ×3/stripe ×2。

## Harmony 决策

vqf/f8c fail-closed；je3 平移 generateRandomUUID。

## 产出

- 证据：`phase-1002-asset-upload-auth.md`
- Fixture：`d02-asset-upload-auth.mjs`（14/14）
- ADR-0946；全量 Replay 见本提交。
