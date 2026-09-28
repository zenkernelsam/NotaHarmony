# Phase 948 报告 — ybg 校验驱动

## 范围

校验驱动本体。纯审计。

## 原版发现

- ybg.c(ka4)：a() null 通过/错误串日志+抛
  ValidationException。
- ybg.d：yn7.MODEL 频道记日志+抛。

## 产出

- 证据：`phase-948-ybg-validator.md`
- Fixture：`d02-ybg-validator.mjs`（4/4）
- ADR-0892；全量 Replay 821 文件绿。
