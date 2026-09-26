# ADR-0738 — 原版 1.4.2 工件级收尾与版本号注册

日期：2026-09-29
状态：已登记（工件面闭合 + T-042 输入证据；无源码变更）
证据：`docs/migration/evidence/phase-794-original-artifact-metadata.md`
Replay：`docs/migration/replays/d02-original-artifact-metadata.mjs`

## 背景

收尾 APK 工件面：dexopt 基线配置、MyScript 资源粒度、
版本号三元组。

## 决策

- 版本号注册为 T-042 输入：原版 1.0.3=vc1014 /
  1.4.2=vc1040002 / Harmony=vc1000000(1.0.0)。
  app.json5 版本目标决策保留至 T-042。
- dexopt baseline.prof/profm：Android ART 专有工件，
  Harmony 无对应面，不移植。
- MyScript 资源粒度修正：引擎数据本体仍在（resources/），
  仅裁 3 个 lite 变体 + en_US.conf/math-sr/dl-raw-content
  更新——与 768 本地 HWR 结论一致。

## 后果

- 1.4.2 工件面闭合；六维证据完成（字符串/资源/资产/
  包/manifest/工件）。
- T-042 具备版本号基线事实。
