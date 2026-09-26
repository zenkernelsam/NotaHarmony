# Phase 805 报告：后端环境与外部端点注册表

日期：2026-09-23
Phase 类型：证据登记（无代码改动）

## 摘要

恢复原版服务端环境枚举与全部外呼端点字面值，形成完整的客户端网络面
注册表。环境枚举两版逐字节一致；Klipy GIF 端点证实 1.0.3 已存在
（修正 Phase 786"UI 面新增"归因）。

## 关键发现

### 环境枚举（`mr0`/`zp0`，42 项，两版相同）

- MAIN×2（production/staging）
- BERRIES×28（strawberry…berryallan 浆果系代号主机）
- FRUITS×10（grape…coffee 水果系代号主机）
- LOCALHOST×2（`10.0.2.2:3000`/`:9090` 模拟器宿主回环）

`hdn` 为带搜索的环境选择页（内部工程工具）。

### 端点注册表

自有：`android-assets.notability.com`（sticker CDN 版本化路径
`/stickers/1.1.0/`）、`otel.notability.com`、`blog`、深链前缀。
第三方：Klipy GIF、Mixpanel 四端点、Firebase/Crashlytics/RemoteConfig、
app-measurement。法务支持：terms/privacy/pricing/dmca/Zendesk/Discord/
社媒。Firebase 项目常量（notability-2475c）为 APK 公开配置。

### delta

环境枚举零变化；新增 sticker CDN 路径、Mixpanel 显式端点、
pricing/compare、Zendesk article、社媒链接扩充（对接 780 social-links）。

## 迁移含义

全部为既有 fail-closed 后端面；NotaHarmony 本地优先无外呼，环境
切换器不移植。本注册表作为 T-042 附件数据集。

## 验证

- `d02-backend-environments.mjs`：6/6 green
- 全量 Desktop Replay 与双 HAP：见提交

## 产物

- 证据：`docs/migration/evidence/phase-805-backend-environments.md`
- Replay：`docs/migration/replays/d02-backend-environments.mjs`
- ADR：`docs/migration/adr/ADR-0749-backend-environments.md`
