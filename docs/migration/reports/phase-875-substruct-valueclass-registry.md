# Phase 875 报告 — 子结构/值类/余枚举登记

## 范围

登记 payload 图中全部内联结构、Kotlin 值类、余枚举与小表；
核对 Harmony 对应层。纯审计阶段，无源改动。

## 原版发现

- **ua0 = 64B SHA-512 资产哈希**（8×Long）——`.note`
  `assets/<sha512>` 键的结构本体。
- 结构族：qo5 8B / cxc 12B / utf 16B / hu1 4B / qed·fqa 8B /
  vy7 16B / v01 13B+ / ukb 16B 录音段。
- 值类：tmf/xgb/mmf/cmf/ymf（Comparable 包装）；imf 普通类。
- 余枚举：ww9（PDF 字段值 STRING/BOOLEAN）、u76（对端指针
  POINTER/PEN/HIGHLIGHTER/ERASER）。

## Harmony 核对

`assets/<sha512>` 键对应 ua0；id/位置层等价；枚举登记备查。

## 产出

- 证据：`phase-875-substruct-valueclass-registry.md`
- Fixture：`d02-substruct-valueclass-registry.mjs`（23/23）
- ADR-0819；全量 Replay 与双 HAP 结果记录于提交。
