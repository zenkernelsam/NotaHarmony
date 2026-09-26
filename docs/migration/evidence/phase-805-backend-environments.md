# Phase 805 证据：后端环境与外部端点注册表

日期：2026-09-23
输入：`decompiled_1.4.2/sources/defpackage/{mr0,kr0,hdn}.java`、
`decompiled_1.0.3/sources/defpackage/zp0.java`、
`decompiled_{1.0.3,1.4.2}/resources/res/values/strings.xml`、
`decompiled_1.4.2/sources/defpackage/*.java` URL 字面值扫描

## 1. 服务端环境枚举（两版一致，42 项）

`mr0`（1.4.2）/ `zp0`（1.0.3）= ServerEnvironment 枚举：
`(enumName, displayName, host, kr0 group)`。枚举名列表逐字节相同。

| kr0 组 | 环境数 | 明细 |
|--------|--------|------|
| `MAIN` | 2 | `PRODUCTION`=notability.com、`STAGING`=staging.notability.com |
| `BERRIES` | 28 | strawberry/blackberry/snowberry/raspberry/blueberry/elderberry/mulberry/salmonberry/cloudberry/cranberry/winterberry/lingonberry/marvinberry/crunchberry/frankenberry/snozzberry/conkerberry/gooseberry/boysenberry/sitrusberry/lumberry/huckleberry/berriedtreasure/berrykeoghan/knottsberry/halleberry/oopsallberry/berryallan |
| `FRUITS` | 10 | grape/banana/avocado/dragonfruit/papaya/passionfruit/pomegranate/guava/sugarplum/coffee |
| `LOCALHOST` | 2 | `10.0.2.2:3000`（模拟器宿主回环）、`10.0.2.2:9090`（Docker） |

`kr0` 组枚举带布尔标记（BERRIES/FRUITS=true，MAIN/LOCALHOST=false）
——为选择器分组可见性/类别标志。

`hdn` = Compose 环境选择页："Search environments"/"Clear search"
搜索框 + 按显示名/主机名过滤 `mr0.J` 全集——内部开发/QA 工具，
随正式包发布但属工程面。

## 2. 外部端点注册表（1.4.2 defpackage 字面值）

### 自有后端/资产

- `android-assets.notability.com`（`io1` 基址）+ `/stickers/1.1.0/`
  （`g2` 版本化路径，sticker CDN，Phase 770）
- `notability.com/app/note/`（深链前缀，Phase 796）
- `blog.notability.com`
- `otel.notability.com`（自有 OpenTelemetry collector——自 1.0.3 已存在）

### 第三方服务

- `api.klipy.com/api/v1/<key>/gifs/`——Klipy GIF 搜索 API（**1.0.3 已存在**，
  Phase 786 的 gif picker 是 UI 面新增而非集成新增）
- `api.mixpanel.com/{engage,flags,groups,track}`（1.0.3 仅裸域——
  1.4.2 显式化四端点）
- `app-measurement.com/{a,s/d}`（Firebase Analytics）
- `firebase-settings.crashlytics.com`（Crashlytics 配置）
- `firebaseremoteconfigrealtime.googleapis.com`（Phase 802 开关面通道）
- `firebaseinstallations.googleapis.com`

### 法务/支持/社媒

- `notability.com/{terms,privacy,pricing,pricing/compare,dmca}`
- `support.gingerlabs.com/hc/`（Zendesk；含 Community Guidelines 与
  Discord 邀请两条 article 链接）
- instagram/twitter/linkedin/youtube/discord.gg 品牌链接

### Firebase 项目常量（strings.xml，公钥性质）

`project_id=notability-2475c`、`firebase_database_url`（RTDB）、
`gcm_defaultSenderId=704682209862`、`google_app_id`、
`google_api_key`（Firebase 客户端密钥为公开标识符，非机密）。

## 3. 版本间 delta

- 环境枚举：零变化（42 项两版相同）。
- 端点新增：`android-assets` sticker CDN 路径、Mixpanel 显式多端点、
  pricing/compare、Zendesk article 链接、社媒链接扩充（对接
  Phase 780 的 social-links 设置项）。

## 4. 迁移含义

- 全部后端面属既有 fail-closed 边界（GMS/Firebase/Mixpanel/自有 API）。
- 环境切换器为工程内部工具——NotaHarmony 无对应需求，登记不移植。
- 本 Phase 完成后，原版的"客户端可达网络面"已有完整清单，作为
  T-042 版本差异报告的附件数据集。
