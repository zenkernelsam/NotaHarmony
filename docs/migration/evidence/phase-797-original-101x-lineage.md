# Phase 797 证据：原版 1.0.x 线内差与三版谱系注册

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——1.0.1→1.0.3 线内差
与完整版本谱系（T-042 输入）。
证据源：`decompiled_1.0.1`、`decompiled_1.0.3`、
`decompiled_1.4.2` strings/assets/manifest diff。
Replay：`docs/migration/replays/d02-original-101x-lineage.mjs`
ADR：`ADR-0741-original-101x-lineage.md`

## 1. 三版谱系（T-042 注册）

| 版本 | versionCode | 证据根 |
|------|-------------|--------|
| 1.0.1 | 1001 | decompiled_1.0.1 |
| 1.0.3 | 1014 | decompiled_1.0.3（移植基线） |
| 1.4.2 | 1040002 | decompiled_1.4.2（最新已分析） |

根目录 `Notability.xapk` 为 4-split 形态，与 1.0.3 xapk
同构（base+arm64+en+xxhdpi）。

## 2. 1.0.1→1.0.3 字符串差（1482→1503，净 +21）

**账户生命周期硬化**（settings 族重写）：
- `account_deletion_message_{text,title}` 展开为
  `confirm_*`/`error_*`/`in_progress`/`sync_failed_*`
  六键状态机；
- 新增 `app__account_deletion_notice_{title,message}`；
- 新增 logout 同步态：`syncing`/`synced_{title,text}`/
  `sync_failed_text`/`unsynced_title`/`sync_now`/
  `sign_out_countdown` + `ok`。

**Paywall 文案重构**：
- 收敛：`lite_feature_{1_label,1_text,4}`、`plus_feature_5`、
  `pro_feature_{2,3,4}_label`、`pro_feature_5`、
  `promo_badge`/`promo_then_price`；
- 展开：`lite_feature_1`/`feature_unlimited`/
  `feature_version_history`/`limited_offer`/
  `pro_feature_5_text`/`pro_feature_6`/`current_plan`/
  `discount_{footnote,original_price}`/`period_{noun,
  adverb}_{month,year}`/`plan_name_starter_short`。

## 3. 资产/类差

- assets：仅 `dexopt/baseline.prof(m)` 重建（无行为差）。
- 类面：无新增 com/gingerlabs 包；defpackage +144
  （混淆类增量，微调）。

## 4. Harmony 侧对照

1.0.x 线内差集中于账户后端面（登出同步态/账户删除流程）
——Harmony 本地优先无账户面，相关功能已随登录/同步
fail-closed 簇登记。paywall 文案随订阅后端簇。
**1.0.3 移植基线相对 1.0.1 无本地功能面差。**

## 5. 结论

三版谱系注册完毕；1.0.x 线内差全部归后端绑定簇，
1.0.3 作为本地行为基线的代表性获证。
