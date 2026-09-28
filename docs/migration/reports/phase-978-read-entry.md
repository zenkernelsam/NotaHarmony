# Phase 978 报告 — 读侧入口 uhj.n + ic3 标志集

## 范围

uhj/ic3。纯审计。

## 原版发现

- `uhj.n` = 根读入口（LE + position+uoffset →
  r29.d 初始化）——读侧统一进 r29 根表。
- `ic3` = 6 位标志集（反射命名注册 hc3）；
  uhj 兼 flag 提供者 + 环形距离/数组切片助手。

## 产出

- 证据：`phase-978-read-entry.md`
- Fixture：`d02-read-entry.mjs`（11/11）
- ADR-0922；全量 Replay 见本提交。
