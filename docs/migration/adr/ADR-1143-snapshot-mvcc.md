# ADR-1143：Compose snapshot MVCC → ArkUI（部分不可等价）

## 状态

已接受（Phase 1199）。

## 决策

Compose 响应式 = **快照 MVCC**：`tjd` 全局快照注册表
（`rjd` 当前+`e` id+锁+回调）+ `zjd`/`psd` 版本化记录
（`c(snapshotId)` 按快照读）+ `osd` 状态基 + `yjd`
MutationPolicy → Harmony **ArkUI `@State`/`@Observed`**。

## 理由

`tjd{rjd,long e,lock,observers}` + `zjd extends psd{
a/b/c(long)}` + `osd implements nsd{yc0}` + `yjd extends gl8`。

## 后果 / 差异

- ArkUI `@State`/`@Observed` = 响应式状态但**无快照
  MVCC**（脏标记重绘，非版本化记录）—— Compose
  隔离/事务/回滚（`Snapshot.withMutableSnapshot`）在
  ArkUI 无直接等价 → 需自研快照语义或接受无事务。
- `MutationPolicy`（equality/never）→ ArkUI `@Observed`
  深度/引用比较策略近似对齐。
- 乐观并发/快照 apply 回调 → Harmony 需自定义。

## 部分 fail-closed

Compose 快照**事务/隔离**语义为 Harmony 不可等价项
（ArkUI 无 snapshot 机制）→ ADR 标记差异；普通
mutableState 响应式可等价。
