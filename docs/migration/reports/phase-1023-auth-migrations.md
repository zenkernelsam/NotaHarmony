# Phase 1023 报告 — 鉴权 DataStore 迁移链

## 范围

`prf`/`qrf` bt2 迁移 + `hq8`/`eua`/`tk8`/`gua` 基元。
纯审计。

## 原版发现

- `prf` = v1→v2 **鉴权清除**：删 authToken+
  emailToDeviceIds+currentUserEmailHash，置
  dataVersion=2（强制再登录，dv<2 时应用）。
- `qrf` = v2→v3：emailToDeviceIds Set JSON
  `"email":"([^"]+)"` 正则格式迁移，置 dv=3。
- `hq8` = DataStore 基类（we2+CountDownLatch+委托）；
  `eua` = Key{name}+equals/hashCode。

## Harmony 决策

迁移链保留；鉴权数据 fail-closed。

## 产出

- 证据：`phase-1023-auth-migrations.md`
- Fixture：`d02-auth-migrations.mjs`（11/11）
- ADR-0967；全量 Replay 见本提交。
