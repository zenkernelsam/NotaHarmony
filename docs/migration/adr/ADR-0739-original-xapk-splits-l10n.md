# ADR-0739 — 原版 1.4.2 XAPK 分包与本地化面登记

日期：2026-09-29
状态：已登记（版本差；无源码变更）
证据：`docs/migration/evidence/phase-795-original-xapk-splits-l10n.md`
Replay：`docs/migration/replays/d02-original-xapk-splits-l10n.mjs`

## 背景

1.4.2 XAPK 含 17 语言分包（1.0.3 仅 en）+ stickers 分包；
manifest.json 暴露 minSdk32/targetSdk36。

## 决策

- 多语言本地化登记为版本差：Harmony 现有 zh_CN
  （649/652）+ base(en)；扩 15 语种属资源工程，
  随 T-042 版本窗口决策。
- stickers/density/ABI 分包已随 760/761/763 登记。
- targetSdk/minSdk 打包事实入册。

## 后果

- XAPK 分层面闭合；本地化语种差明确（zh 已覆盖，
  其余 15 语种为资源缺口非代码缺口）。
