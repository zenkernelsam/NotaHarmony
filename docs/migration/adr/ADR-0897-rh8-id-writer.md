# ADR-0897 — `rh8` 线协议三件套：qo5 Id 写器/工厂 + closeFinally

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`rh8` = R8 归并工具类；线协议三件套：

- `O(qo5,a)` = **Id 8B 内联写器**：`t(4,8)`+`w(ts)`+`s(2)`+`y(site)`
  逆序 → `{site:UShort@0, pad@2, timestamp:UInt@4}`。
- `b(int,short)` = **Id 工厂**（序列化→`b()` 反读→`ybg.c`→`q` 归还）。
- `q(AutoCloseable,Throwable)` = Kotlin `closeFinally`（含
  ExecutorService shutdown+await 特判）。

`qo5` = `Id{site,timestamp}` —— 实体 Lamport ID，`cxc` SeqId 的
8B 前缀（cxc 追加 index@8）。

## Harmony 决策

ID 写侧逆序布局与读侧 `{site@0,timestamp@4}` 等价（Replay 覆盖）；
`q` 以 `finally`/`using` 表达。

## Parity 状态

等价。

## 验证

- `d02-rh8-id-writer.mjs`：17/17 通过。
- 全量 Replay 826 文件绿，见 Phase 953 提交。
