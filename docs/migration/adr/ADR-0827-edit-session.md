# ADR-0827 — `tzc`/`aa9` 编辑会话层

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `tzc extends zac`（Closeable actor）= 编辑会话：
  `O`=siteId、`P/Q`=bs1 双计数器（`l96.M(s)`=`bs1(0,site)`）、
  `M`=aa9 应用执行器、`N`=b40 广播面、`U`=yc6 寄存器宿主、
  `K/L`=actor 信箱；构造 fail-closed 于 site 未解析。
- `v0` 通用事务：`fsi.s`→ops、`b(map,eof)`→变更集、
  `M.c(list,mapB,λ)`→aa9 应用（suspend）。
- `aa9 extends zac` = 应用执行器：`c` JADX 不可恢复
  （265 指令 suspend SM）；`m` 经 `l51.i(k1a)` 命令通道派发。
- `k1a` = 应用命令 `{o69 target, rh8.b opId}`。

## Harmony 决策

单写者会话 ↔ PageRepository/OpStoreImpl 顺序写；
bs1 ↔ nextOperationTimestamp；fail-closed site ↔ siteId
校验；actor+command ↔ 顺序提交管线（无多 actor 需求）。

## Parity 状态

等价（写侧架构语义对齐；actor 实现形式差异已在架构
ADR 覆盖）。

## 验证

- `d02-edit-session.mjs`：20/20 通过。
- 全量 Replay 与双 HAP 构建见 Phase 883 提交。
