# ADR-0758 — APK 签名块结构与签名身份谱系

- 状态：Accepted
- 日期：2026-09-26
- 关联：Phase 794/797(版本谱系)、Phase 811(打包层)

## 背景

原版三个版本的签名身份与 APK Signing Block 结构未登记。
签名身份是升级兼容与"是否同一发行方"的硬证据。

## 取证结论

- 三版 base APK 均含 APK Sig Block，且 ID 集一致：
  v2(`0x7109871a`)+ v3(`0xf05368c0`)+ source stamp
  (`0x6dff800d`)+ Play 元数据(`0x2146444e`)+ 渠道 Brew 戳
  (`0x42726577`)。
- v3 signer 证书 SHA-256 前缀 `8fb7a01443b50be6` 在
  1.0.1/1.0.3/1.4.2 完全一致 —— 同一签名身份贯穿谱系；
  渠道戳为外层附加，不影响 signer。

## 决策

1. 签名身份登记为**版本谱系佐证**:三版同源签署，升级链合法。
2. Harmony 侧 HAP 签名(profile/证书体系)是异构信任根，
   Android signer 不可移植，登记为平台边界；当前工程未配置
   signingConfigs,`Will skip sign` 警告为已知状态，不阻塞
   静态验证。
3. 渠道/商店戳(Brew、Play metadata)登记为分发层信息，不移植。

## 后果

- 版本谱系证据链补齐签名身份一环。
- Replay `d02-signing-identity.mjs` 11/11 钉住签名块结构与
  证书一致性。
