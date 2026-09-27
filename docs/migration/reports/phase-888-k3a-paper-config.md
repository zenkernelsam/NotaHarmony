# Phase 888 报告 — `k3a` 纸面配置六字段

## 范围

登记 887 遗留的 k3a 六访问器细节。纯审计，无源改动。

## 原版发现

- `fag.o0` = k3a 六字段写器：{n3a 模板@0, Float@1,
  Bool×2@2/3, hu1 色@4(z5c.P), cmf 枚举@5}；布尔写期间
  `aVar.l` 模式标记留档。
- `fag.k` = 存根工厂；a79.Q 掩码 111 = 仅色显式其余默认
  （bit5/6 再证省略参数序号）。
- `tu1.a` = pce 惰性默认纸色；`cmf` = 字节值类枚举；
  `n3a` = LINES/DOTS/GRID。
- `tu1.a/c/d` = hu1 构造族、`tu1.b` = hu1→int。

## Harmony 核对

k3a 六槽 ↔ PageBackgroundModel；hu1 色 ↔ 颜色结构；
tu1 默认色 ↔ 默认纸。

## 产出

- 证据：`phase-888-k3a-paper-config.md`
- Fixture：`d02-k3a-paper-config.mjs`（16/16）
- ADR-0832；全量 Replay 与双 HAP 结果记录于提交。
