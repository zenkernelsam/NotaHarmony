# Phase 1257 证据 — nnf/ekd/dve 有界撤销栈

来源：`defpackage/{nnf,ekd,dve,isd,ije,tab}.java`。

## `nnf` = 有界撤销/重做栈

```java
final class nnf {
    int a;              // capacity
    ekd b;              // undo ops
    ekd c;              // redo ops
    nnf(i, list, list2) {
        if (i<=0) "Capacity must be a positive integer";
        if (initial>cap) "...size greater than capacity";
        b.addAll(undo); c.addAll(redo);
    }
}
```

## `ekd` = Parcelable+SnapshotStateList

```java
ekd implements Parcelable, nsd, List, RandomAccess, jk6 {
    isd I;              // snapshot-backed list delegate
    // nsd = Compose snapshot-state-list iface!
    add/addAll/clear/... List 委托到 isd
}
```

## `dve` = 逆操作记录

```java
dve { int a; String b,c;     // pos + before/after text
      long d,e,f; boolean g; // pos/ts
      oje h; }               // 关联状态
tab i;                       // companion
ije a();                     // →op 物化
```

## 语义

- `nnf` = **有界双栈** `{cap, ekd undo, ekd redo}` +
  容量守卫 —— 撤销/重做 op 栈；
- `ekd` = **`SnapshotStateList`+`Parcelable`** —— 撤销栈
  是快照状态列表（compose-reactive）+可跨进程 Parcelable;
- `dve` = 逆操作记录 `{pos, before/after, ts, oje}` —
  undo 存 inverse edit；
- `isd`/`ije`/`tab`/`jk6` = snapshot-list delegate/op/companion。

## Harmony 决策

nnf/ekd → Harmony `@Observed`/`@State` ArrayList 有界
栈（cap 守卫）+`dve` 逆操作 —— 撤销语义保真。

## 产出

- fixture `d02-undo-stack.mjs`（10 断言）。
- ADR-1201；中文报告。
