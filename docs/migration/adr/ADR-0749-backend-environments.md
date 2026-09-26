# ADR-0749：后端环境与端点面登记（fail-closed 全集）

- 状态：accepted
- 日期：2026-09-23
- 证据：`docs/migration/evidence/phase-805-backend-environments.md`
- Replay：`docs/migration/replays/d02-backend-environments.mjs`

## 决定

登记原版完整后端网络面为 fail-closed 证据集；不实现环境切换器、
不引入任何服务端端点配置。NotaHarmony 维持本地优先、零网络依赖。

## 依据

- `mr0`/`zp0` 环境枚举 42 项两版逐字节一致：MAIN(2)/BERRIES(28)/
  FRUITS(10)/LOCALHOST(2,模拟器回环别名)——内部工程环境切换器
  （`hdn` 可搜索 Compose 页），非用户功能。
- 端点注册表完整落地：自有 CDN（android-assets stickers 1.1.0）、
  自有 OTel collector、Klipy GIF、Mixpanel、Firebase 全家桶、
  Zendesk、法务/社媒链接；全部后端绑定面均属既有 fail-closed。
- Firebase 项目常量为 APK 公开配置值（非机密），登记为证据。
- Klipy GIF 端点 1.0.3 已存在——Phase 786 的 GIF picker 为 UI 面
  新增而非集成新增（修正归因）。

## 影响

客户端可达网络面清单完整，作为 T-042 版本差异报告的附件数据集。
NotaHarmony 无外呼需求，环境切换器为工程内部工具，均不移植。
