# ADR-0972 — 导出 bundle（.note）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `zk9.a` = 导出入口（Context+k79 lazy）：在
  `t13.K` dispatcher 启 `yk9` coroutine。
- `yk9` 写 `manifest.json`+`noteBundle`(r29
  FlatBuffer)+`assets/`——.note = zip 容器。
- `pa0`/`cba`/`cp5`/`zjb`（Phase 996）产 wa0
  资产元数据进 manifest。

## Harmony 决策

导出格式等价——zip+manifest+FlatBuffer+assets；
`@kit.CoreFileKit` zip；`w59` 进度→回调。

## Parity 状态

等价。

## 验证

- `d02-export-bundle.mjs`：10/10 通过。
