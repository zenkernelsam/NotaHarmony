# Phase 1254 证据 — tjd/osd/yjd/zjd/p6a Compose 快照 MVCC

来源：`defpackage/{tjd,osd,yjd,zjd,p6a,psd,akd,rjd}.java`。

## `tjd` = 全局快照核

```java
static rjd d;                // 当前全局快照
static long e;               // snapshot-id 计数器
static Object c;             // 快照锁
static List h,i;             // apply/write 观察者
static pjd f, cs5 g, s65 j;  // advance/pin/observer
static zec a, yc6 b;         // 注册表
```

## `osd` = StateObjectImpl 基

```java
yc0 I;                       // first-state-record 头
c(i)/g(i)                    // 记录链读/写 kind
```

## `zjd extends psd` = StateStateRecord（版本化记录）

`zjd(long snapshotId, Object value)` + `a`/`b`/`c` =
记录 copy/merge —— MVCC 版本化状态记录。

## `p6a extends osd implements Parcelable,yjd` = MutableState

```java
akd J;                       // mutation policy (equals/merge)
zjd K;                       // 状态记录
d()→psd; e(psd,psd,psd);     // 3-way merge/冲突解决
getValue(); Parcelable;      // state 读写 + 跨进程
```

## 语义

- `tjd` = Compose 全局快照：`rjd` 当前 + `e` 版本计数 +
  `c` 锁 + `h`/`i` observers —— MVCC 快照隔离；
- `osd`/`zjd` = 状态对象+版本化记录链（snapshot-id）；
- `p6a` = `MutableState`（`akd` mutation policy + `e` 3-way
  merge + Parcelable）—— **冲突解决/合并语义**;
- 写时读 `tjd.d` 当前快照，提交时 `e` 版本比较 merge。

## Harmony 决策

Compose MVCC 快照 → Harmony `@State`/`@Observed`+
自研版本化 state（或 AppStorage）—— 快照语义保真。

## 产出

- fixture `d02-snapshot-mvcc.mjs`（10 断言）。
- ADR-1198；中文报告。
