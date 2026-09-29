# Phase 1020 报告 — xrf 鉴权 DataStore

## 范围

`xrf extends hq8` 鉴权 Preferences store。纯审计。

## 原版发现

- 5 `eua` 键：dataVersion/authToken/emailToDeviceIds/
  currentUserEmail/currentUserId。
- `p = m18.m0(prf, qrf)` 迁移链；`g`/`h`/`i`/`j`
  `pce` 懒 Flow getter；`hq8` DataStore 基类。

## Harmony 决策

preferences 等价；token/身份加密存（AssetStore）；
鉴权 fail-closed。

## 产出

- 证据：`phase-1020-auth-datastore.md`
- Fixture：`d02-auth-datastore.mjs`（10/10）
- ADR-0964；全量 Replay 见本提交。
