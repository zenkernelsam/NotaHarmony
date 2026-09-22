# 原版证据：LOCK/UNLOCK 对单元素选区无条件清选（dhb case18/19）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 605 依据。

## 1. itc 单元素分支（dhb.java:18001-18034）

```java
if (ktcVar instanceof itc) {
    qo5 qo5Var32 = ((itc) ktcVar).a;
    be5 be5VarI = tl7.I(x09VarN18, qo5Var32, 6);
    if (be5VarI instanceof oy0) {          // hp5 图片 / xhe 文本 / r08 块
        objX = u5j.n(x09, [id], …, !((oy0) be5VarI).t());
    } else if (be5VarI instanceof m4d) {   // n5d 形状（cih.a 校验）
        objX = u5j.x(x09, [id], …, !((n5d) m4dVar).t(), 8190);
    }
    xj2.A(xscVar.h(), null, null, new wsc(i4, cg2Var, xscVar, objX), 3);
    fvbVar.a();                            // ← 无条件清选
}
```

- `oy0`（ly3 子接口）实现者：`hp5`（图片）、`xhe`（文本块）、`r08`。
- `m4d`/`n5d` = 形状实体；`n5d.t()` = `positionLockedRegister`（n5d.java:214）。
- 笔画实现（`fkb`/`gkb`/`k85` 等）非 `oy0`/`m4d` → `objX=null`，
  `wsc` 收到空载荷（无写操作），但 `fvb.a()` 仍执行——
  **单笔画上点 LOCK 的可观察效果 = 清除选区**。

## 2. 多选分支（dhb.java:18015-18034 + xsc.java:216-243）

```java
Boolean boolK = xscVar.k(ktcVar);          // null ⟺ 选区无形状
// xsc.k：遍历 h()；非 m4d（非形状）→ return null；
//        cih.a 形状统计"全部 positionLocked？"→ z2
if (boolK != null) {
    boolean z15 = !boolK;                   // 目标态 = !全锁
    for (id : h()) {
        m4d q8 = tl7.Q(id, x09);
        if (q8 != null && cih.a(q8) && ((n5d) q8).t() != z15)
            arrayList9.add(id);             // 仅收集需翻转的形状
    }
    if (!arrayList9.isEmpty()) {
        xj2.A(…, new vz6(xscVar, x09, arrayList9, z15, null), 3);
        fvbVar.a();                         // ← 仅在确有翻转时清选
    }
}
```

- 多选 LOCK/UNLOCK 只作用于形状；笔画/文本/图片/数学块不翻转。
- 空翻转集（全形状已在目标态）→ 无 `fvb.a()` → **选区保留**。

## 3. Harmony 缺口与修复

`setSelectedPositionLocked` 空 diff 直接 return：单笔画（不可锁定，
LOCK 菜单按 selectedCount===1 显示）点击后选区保留——与原版
`fvb.a()` 无条件清选不符。修复：空 diff 早退时若选区为单元素
（无组、五类合计==1）补 `clearSelectionWithRegisterReset()`；
多选空 diff 维持保留（`arrayList9.isEmpty()` 语义一致）。

## 4. 偏差

- `wsc` 对 `objX=null` 的内部处理（日志/静默）未反编译到底；
  按无可观察副作用处理（fail-closed）。
- `esc` 菜单项可见性生产者未解码：单笔画上原版是否显示 LOCK
  不可证；Harmony 维持显示，点击行为对齐为"清选"。
