# Phase 883 报告 — `tzc`/`aa9` 编辑会话层

## 范围

登记 op 写侧会话/actor 层。纯审计，无源改动。

## 原版发现

- `tzc extends zac` = 编辑会话：O=siteId、P/Q=bs1 双计数器、
  M=aa9 应用执行器、N=b40 广播、U=yc6 寄存器、K/L=信箱；
  构造 fail-closed「Note with unresolved editor site」。
- `v0` 事务：`fsi.s`→ops、`b(map,eof)`→变更集、`M.c`→aa9
  应用。
- `aa9 extends zac` = 应用执行器：`c` 方法 JADX 不可恢复
  （265 指令 suspend SM 留档）；`m` 经 `l51.i(k1a)` 通道
  派发。
- `k1a` = 应用命令 {o69 目标, qo5}；`l96.M(s)`=`bs1(0,site)`。

## Harmony 核对

单写者 ↔ 顺序写路径；计数器 ↔ nextOperationTimestamp；
fail-closed site ↔ siteId 校验。

## 产出

- 证据：`phase-883-edit-session.md`
- Fixture：`d02-edit-session.mjs`（20/20）
- ADR-0827；全量 Replay 与双 HAP 结果记录于提交。
