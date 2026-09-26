# Phase 814 — APK 签名块与签名身份谱系

## 目的

三个原版版本(1.0.1 / 1.0.3 / 1.4.2)的签名身份与 APK Signing
Block 结构尚未登记。签名身份是版本谱系与升级兼容性的硬证据。

## 取证路径

- `Notability_1.0.1/com.gingerlabs.notability.apk`
- `Notability_1.0.3/com.gingerlabs.notability.apk`
- `Notability_1.4.2/com.gingerlabs.notability.apk`
- 解析 APK Signing Block(`APK Sig Block 42` magic,EOCD 前置)

## Signing Block 结构(三版一致)

每版 base APK 的签名块含 5 个 ID 值对：

| Block ID | 大小 | 身份 |
|---|---|---|
| `0x7109871a` | 2613 B | APK Signature Scheme **v2** |
| `0xf05368c0` | 2613 B | APK Signature Scheme **v3**(含 signer 证书链) |
| `0x6dff800d` | 3057 B | source stamp(Google Play 商店投递戳) |
| `0x2146444e` | ~4178 B | Play 元数据(依赖/渠道信息) |
| `0x42726577` | ~3832 B | 渠道分发戳("Brew" 标识,第三方商店渠道戳) |

签名方案栈 v2+v3 一致(最低 minSdk 对齐 v2,rotation-proof 用 v3),
source stamp 存在说明包经过 Play 渠道签发；`Brew` 戳来自
APKPure/APKCombo 分发的再戳记。

## 签名身份(v3 signer 证书 SHA-256)

| 版本 | signer cert SHA-256(前 16 hex) |
|---|---|
| 1.0.1 | `8fb7a01443b50be6` |
| 1.0.3 | `8fb7a01443b50be6` |
| 1.4.2 | `8fb7a01443b50be6` |

**三个版本 signer 证书完全一致** —— 同一签名身份贯穿
1.0.1→1.0.3→1.4.2 谱系，无换签、无重打包破坏。第三方渠道戳
(Brew)附加在外层，不改变 v3 signer。

## Harmony 侧

Harmony HAP 签名体系为 profile 驱动(`build-profile.json5`
signingConfigs)。当前工程未配置签名档，构建输出
`Will skip sign 'hos_hap'` 警告（已知，不阻塞静态验证）。

- 签名身份不可移植：Android signer 证书与 Harmony 开发者证书
  是不同体系的信任根，登记为平台边界。
- 原版 v2/v3 双方案栈对应 Harmony 的 HAP 签名(profile + 证书),
  语义等价物存在，部署期配置，非代码面。

## 结论

签名身份层闭合：三版同一 signer 证书、同一 v2+v3+stamp+渠道
结构；渠道分发戳(Brew)确认为外层附加不影响 signer 一致性。
