# ADR-1069：序列树游标（immutable/mutable 双态）

## 状态

已接受（Phase 1125）。

## 决策

- `swc` = 游标 iface `{a→qwc, c→long, d(hr5)→hr5, e(rwc)→rwc}`。
- `qwc` = 不可变 `{f8d,int}`；`rwc` = 可变 `{f8d,int=-1}`，
  未绑 `ba6.d0` 抛。
- `d(hr5)` = `f8d.a(hr5,slot)` 锚点出参读。

## 依据

双态游标互转；槽位锚读；未初始化 fail-loud。

## 后果

Harmony：单 cursor + freeze 标志；锚读写出参语义保留。
