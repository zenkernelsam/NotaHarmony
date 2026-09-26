# Phase 794 — 原版 1.4.2 工件级收尾与版本号注册

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-794-original-artifact-metadata.md`
ADR：`ADR-0738-original-artifact-metadata.md`
Replay：`d02-original-artifact-metadata.mjs`（6/6）

## 本阶段做了什么

收尾 APK 工件面并注册版本号三元组作为 T-042 输入。

## 发现

- 版本号：1.0.3=vc1014 / 1.4.2=vc1040002 /
  Harmony=vc1000000（"1.0.0"）——版本目标属 T-042。
- dexopt/=ART 基线 profile（Android 专有，不移植）。
- MyScript 资源细化：引擎本体仍在（resources/ 五目录），
  仅裁 3 个 lite .res 变体；en_US.conf/math-sr/
  dl-raw-content 内容更新——与 768 本地 HWR 一致。

## 验收

- Replay 6/6 绿；六维证据面闭合；全量套件与双 HAP
  随本阶段执行。
