# ADR-0691 — LIBRARY_HOME 旗标判定更正：默认开启的延迟移植缺口

日期：2026-09-25
状态：已落地（更正 ADR-0655 的旗标判定；接续 ADR-0690 同类更正）

> **落地（2026-09-25，ADR-0694）**：本 ADR 登记的延迟移植缺口已
> 由 Phase 746 完成移植 —— Home 导航项 + ksh 首页内容（双 CTA +
> 收藏/最近卡行）已实现；study_up_next 与 starter 配额变体维持
> fail-closed。本文保留作为旗标判定更正的历史记录。

## 背景

ADR-0655 将 `LIBRARY_HOME`（`ac4.F0`，序号 47）登记为
“旗标关闭态 = Harmony 现状”。复核发现与 ADR-0690（ZOOM_VIEW）
相同的判定错误：该旗标为 `zb4.L`（PRODUCTION）级，`lc4.a`
ordinal-3 分支直读远程配置 `trb.e(tsb.c)`，键
`"androidLibraryHome"` 的打包默认（`core_remoteconfig__remote_config_
defaults.xml`）为 `true` —— 1.0.3 原版资料库导航**默认含 Home 分区**
（`ajh:335` 插入 `feature_library__home` 项，`va7`/`wa7` 门控其图标）。

## 决策

1. 更正 ADR-0655 的旗标判定：Home 分区由“旗标关闭正确缺省”
   改登记为**延迟移植缺口（port-deferred gap）**。Harmony 经典
   Library 继续无 Home 分区，但理由是“实现未就绪”而非“对等原版”。
2. Home 分区组成按原版 `ksh` 族登记：
   - 可移植部分：`home` 导航项（`tnc.a` 图标）、"Let's get started"
     双 CTA 卡（`home_record_lecture`/`home_take_notes`）、
     `home_favorite_notes` 区、`home_recent_notes` 区；
   - 不可移植部分：`home_study_up_next` 依赖 Learn 后端，维持
     ADR-0652 fail-closed——实施 Home 时该区应整体缺省并注明。
3. 远程默认值全量扫描收官：`core_remoteconfig__remote_config_defaults.xml`
   51 键 × `ac4` 旗标注册表交叉核对完毕，默认 `true` 的旗标除
   本项与 ADR-0690 外，均为已移植功能或有效的服务端/供应商
   fail-closed 边界；默认 `false`/非布尔键维持旗标关闭态登记
   （含 ADR-0658 A 类各行）。此后远程旗标域默认方向已全部
   审计闭环。

## 证据

- `docs/migration/evidence/original-library-home-flag-correction-jadx-2026-09-25.md`

## 验证

- `docs/migration/replays/d02-original-library-home-flag-correction.mjs`：
  旗标求值链 + 默认值 + 消费方锚点 + Harmony absence + 更正登记断言。
- 全量 Replay 与双 HAP 构建随本阶段通过。
