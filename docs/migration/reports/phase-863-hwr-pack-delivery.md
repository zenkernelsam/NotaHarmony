# Phase 863 报告 — 手写识别语言包投递层登记

## 范围

登记 `data/handwritingrecognition` 的投递契约：dc5 23 语言枚举、
gg1 双通道安装器、下载 Worker 与三道异常门；核对 Harmony
fail-closed 适配。纯审计阶段，无源改动。

## 原版发现

- `dc5`：23 语言（en_US 默认；TW/HK/MO Hant 地区集；I=localeCode
  写 MyScript recognizer.lang）。
- `gg1`：内置仅 en_US；其余 22 语言经 Play Asset Delivery +
  自有 CDN（v4.4.0，`android-assets.notability.com`）下载。
- 异常门：包缺失 / MyScript 证书不支持 Math 识别器 / Play 交付
  不可用（IOException）。

## Harmony 核对

- 23 语言表、en_US 默认、zh 地区门、遗留 ISO 重映射、四源解析链
  全部对齐。
- 投递层 fail-closed：provider-null→null、四道兼容门表达
  （无 Play Asset Delivery / MyScript 证书）。

## 产出

- 证据：`phase-863-hwr-pack-delivery.md`
- Fixture：`d02-hwr-pack-delivery.mjs`（33/33）
- ADR-0807；全量 Replay 与双 HAP 结果记录于提交。
