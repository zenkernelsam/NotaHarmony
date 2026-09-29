# ADR-0967 — 鉴权 DataStore 迁移链

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `prf` = v1→v2 **鉴权清除**：删 authToken+
  emailToDeviceIds+currentUserEmailHash，置
  dataVersion=2（强制再登录）。
- `qrf` = v2→v3：置 dataVersion=3 + 迭代
  emailToDeviceIds Set 用 `"email":"([^"]+)"` 正则
  格式迁移。
- `eua`/`tk8`/`gua`/`hq8` DataStore 基元。

## Harmony 决策

迁移链保留（v2 清 auth 语义关键）；Harmony
preferences 初始化按 dataVersion 应用；鉴权本体
fail-closed。

## Parity 状态

迁移语义等价；鉴权 fail-closed。

## 验证

- `d02-auth-migrations.mjs`：11/11 通过。
