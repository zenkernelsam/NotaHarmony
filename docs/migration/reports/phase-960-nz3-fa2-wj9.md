# Phase 960 报告 — nz3/fa2.w/wj9/qub.l 残余助手

## 范围

nz3 + fa2.w + wj9 + qub.l/uq9.m。纯审计。

## 原版发现

- `nz3` = EnumEntries；uq9.m 越界→NONE 实证。
- `fa2.w` = 负长日志统一入口。
- `wj9` = 元素提供器（case9/10=qub/f2c cxc 就地填充）。
- `qub.l` = 12B 步长零拷贝元素访问器。

## 产出

- 证据：`phase-960-nz3-fa2-wj9.md`
- Fixture：`d02-nz3-fa2-wj9.mjs`（15/15）
- ADR-0904；全量 Replay 833 文件绿。
