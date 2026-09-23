# 原版证据：页面清空持久层落地（JADX，decompiled_1.0.3）

Phase 649 的原版依据。类文件均取自
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\`。

## 1. 分发入口（fd2 case1）

`fd2.java` 页 cell 上下文菜单分发（Phase 647 已建档）：

```java
case 1:
    de2Var.n(m18.l0(new tz9(cxcVar)));
```

Clear Page 对**任意页键**生效——不区分当前页。

## 2. 批操作入口（de2.n）

`de2.java:183-190`：

```java
public final void n(List list) {
    if (list.isEmpty()) {
        a.c(yn7.MODEL, "Clear pages with empty page selection", null, null);
    } else {
        xj2.A(this.M, null, null, new ae2(this, list, ef2Var, 1), 3);
    }
}
```

空集 fail-closed；非空走 `ae2` **variant 1**，经 `xj2.A` 协程
批量应用（变体编号：m=0 Bookmark、n=1 Clear、o=2 Copy、p=3 Cut、
q=4 Delete、r=5 Duplicate）。

批量分发侧 `n9j` tc2 default(case6)：`de2.n(au1.T1(f))`——
对整个选中集一次下发，执行后**保持选择态**（不调用 `de2.u()`）。

## 3. 应用体（ae2 variant 1）

`ae2.java:132-165`（case 1 分支）：

```java
ArrayList arrayList = new ArrayList();
Iterator it2 = list.iterator();
while (it2.hasNext()) {
    au1.O0(arrayList,
        ((a79) x09Var2).j.m(((tz9) it2.next()).a).keySet());
}
if (!arrayList.isEmpty()) {
    List listL1 = m18.l0(u5j.l(x09Var2, arrayList, null, 14));
    dof dofVar2 = de2Var.O;
    this.J = 2;
    if (x82.I(m1dVar2, listL1, dofVar2, iw3Var, this) == ii2Var) {
        return ii2Var;
    }
}
```

逐页收集 `j.m(pageKey).keySet()`（该页**全部元素键**）汇入同一
ArrayList → `u5j.l(x09, ids, null, 14)` 生成实体删除 op
（`u5j.l` 即 DELETE_ENTITIES 载荷构造，掩码 14）→ `x82.I`
记帐通道应用，`dof` = undoable 策略标记（Phase 640 已证
`cof.toString()="NotUndoable"`，`dof` 为可撤销对应物）。

**语义等价式**：Clear(page) = 对该页全部活动元素一次
DELETE_ENTITIES 可见性删除，经记帐通道 → 可撤销。

## 4. 组与跨页约束

原版组模型中组成员同属一页（`x09.j.m(pageKey)` 的键空间即页内
元素）；整页元素键集合覆盖时组随成员一并失效。Harmony 的
`OriginalSelectionGroup` 同属页域模型，故本 Phase 将
"成员全集被删除覆盖的组"一并删除（跨页残留组保留并登记，
与原版一致地不主动触碰）。

## 5. Harmony 映射（Phase 649）

| 原版 | Harmony |
|---|---|
| fd2 case1 → de2.n(单页) | `dispatchPageContextAction('clear')` → `clearPageAt(index)` |
| tc2 case6 → de2.n(选中集) | `dispatchPageSelectionAction('clear')` 逐页 `clearPageAt` |
| ae2 v1：页内全部元素键 → DELETE_ENTITIES | `StrokePersistence.clearOriginalPageContent`：`loadCurrentSnapshot` 全量 → `OriginalDeleteEntitiesOperationApplier` 可见性删除 |
| x82.I 记帐 → 可撤销 | companion `OpType.DELETE_ELEMENTS` + `history` → `PERSISTED_PAGE_MUTATIONS`，撤销经导航+回放 |
| 当前页 Clear（画布管线） | 保持 `clearPageSignal++`（选择→删除→撤销一体，Phase 647 建档） |
| 空页 / 空选中集 fail-closed | 空页返回 `null`（无历史动作）；空集 `failClosed` toast |
