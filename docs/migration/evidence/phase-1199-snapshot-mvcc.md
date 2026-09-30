# Phase 1199 证据 — Compose snapshot MVCC 内部（tjd/zjd/psd/yjd/osd）

来源：`defpackage/{tjd,zjd,psd,yjd,osd}.java`。

## `tjd` = **全局 snapshot 状态**（Compose Snapshot 运行时）

```java
tjd:
  zec a, yc6 b         // apply/observe 回调
  Object c             // 全局锁
  rjd d                // **当前 snapshot**（head）
  long e               // snapshot id 计数器
```

Compose `SnapshotKt` 静态：`rjd` 当前快照 + `e` 递增 id +
`c` 锁 + `a`/`b` 观察/apply 回调 —— 全局 MVCC 注册表。

## `zjd extends psd` = 版本化 state-record

```java
zjd(long snapshotId, Object value):
  a(psd)      // merge 记录
  b()→psd     // 读
  c(long)→psd // **按 snapshotId 读记录**（MVCC 读旧值）
```

`psd` = state-record 基 —— 每 MutableState 值存为版本化
记录（snapshot-id 链）→ 读用当前快照 id 找可见记录。

## `osd implements nsd` = snapshot-state 基

`{yc0 I}` + `c(int)`/`g(int)` —— 快照 id 跟踪（state 的
snapshot 版本）。

## `yjd extends gl8` = `SnapshotMutationPolicy` iface

`structuralEquality`/`referentialEquality`/`neverEqual` ——
notify-equality 策略（`p6a` setValue 判等用）。

## 判定

**Compose 响应式 = 快照 MVCC**：
- `tjd` 全局快照注册表（当前快照+id 计数+锁+回调）。
- `zjd`/`psd` 版本化状态记录（snapshot-id 链 → MVCC
  读旧/写新）。
- `osd`/`yjd` 状态基 + 判等策略。
- `p6a` MutableState = `zjd` 记录 + `tjd` 全局。

→ ArkUI `@State`/`@Observed`：响应式状态但**无快照
MVCC**（ArkUI 用脏标记重绘而非版本化记录）——
Compose 隔离/回滚语义在 ArkUI 无直接等价（快照
事务/restore 需自研）。

## 产出

- fixture `d02-snapshot-mvcc.mjs`（10 断言）。
- ADR-1143；中文报告。
