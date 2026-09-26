# Phase 814 — APK 签名块与签名身份谱系(中文报告)

## 本阶段结论

三版原版 base APK(1.0.1/1.0.3/1.4.2)签名身份完全一致：
v3 signer 证书 SHA-256 前缀 `8fb7a01443b50be6` 三版相同。

## 签名块结构(三版一致)

- `0x7109871a` v2 签名(2613B)
- `0xf05368c0` v3 签名(2613B,含 signer 证书链)
- `0x6dff800d` source stamp(Play 商店投递戳)
- `0x2146444e` Play 元数据(~4178B)
- `0x42726577` 渠道 Brew 戳(第三方商店附加)

## 意义

- 同一 signer 贯穿 1.0.1→1.0.3→1.4.2，版本谱系完整、升级链合法。
- Brew 戳确认为第三方渠道外层戳记，不改变 v3 signer。
- Harmony 侧：HAP 签名体系为 profile 驱动异构信任根,Android
  signer 不可移植（平台边界登记）；当前工程未配置签名档，
  `Will skip sign` 为已知非阻塞状态。

## 验证

- Replay:`d02-signing-identity.mjs` 11/11;全量 687/687 绿。
- 双 HAP(note@default + note@ohosTest)构建成功。

## 交付物

- `docs/migration/evidence/phase-814-signing-identity.md`
- `docs/migration/replays/d02-signing-identity.mjs`
- `docs/migration/adr/ADR-0758-signing-identity.md`
- 本报告
