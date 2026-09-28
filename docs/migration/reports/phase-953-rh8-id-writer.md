# Phase 953 报告 — `rh8` 线协议三件套

## 范围

rh8.java（2370 行 R8 归并类）线协议成员 + qo5.java。纯审计。

## 原版发现

- `O` = qo5 Id 8B 内联写器（逆序：timestamp→pad→site）。
- `b` = Id 工厂（builder→反读→ybg.c→closeFinally）。
- `q` = Kotlin closeFinally + ExecutorService 特判。
- `qo5` = `Id{site:UShort@0, timestamp:UInt@4}`，cxc 的 8B 前缀。

## 产出

- 证据：`phase-953-rh8-id-writer.md`
- Fixture：`d02-rh8-id-writer.mjs`（17/17）
- ADR-0897；全量 Replay 826 文件绿。
