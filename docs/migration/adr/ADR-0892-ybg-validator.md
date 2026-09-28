# ADR-0892 — ybg 校验驱动

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`ybg.c(ka4)`=最简契约执行器：a() 返回 null
通过、错误串经 `yn7.MODEL` 记日志后抛
`ValidationException`——失败关闭无降级。

## Harmony 决策

校验失败=抛错；日志先行。

## Parity 状态

等价。

## 验证

- `d02-ybg-validator.mjs`：4/4 通过。
- 全量 Replay 821 文件绿，见 Phase 948 提交。
