# 原版页书签切换可撤销性 — jadx 证据（2026-09-23）

阶段：Phase 640。结论：原版页书签切换经 `x82.I(..., dof, ...)` 日志通道
应用，`dof`/`cof` 是显式撤销策略标记——`dof` 为可撤销（默认），
`cof.toString() == "NotUndoable"` 为不可撤销。Harmony 此前只写
ModifyPage op 不落历史动作，属真实缺口；本 Phase 以 PAGE_BOOKMARK
companion 补齐。

## 原版证据（decompiled_1.0.3）

### ae2 variant 0 —— 书签切换协程

`defpackage/ae2.java`（`case 0`，`this.I == 0` 分发）：

```java
m18.F0(obj);
this.J = 1;
objK = de2.k(de2Var, this);              // 取 content-manager 上下文
if (objK == ii2Var) { return ii2Var; }
k1a k1aVar = (k1a) objK;
m1d m1dVar = (m1d) k1aVar.I;
x09 x09Var = (x09) k1aVar.J;
List list2 = ((a79) x09Var).i;           // 笔记当前页表
List list3 = this.L;                     // 选中页 id 列表
if (list2 == null || !list2.isEmpty()) {
    Iterator it = list2.iterator();
    while (true) {
        if (it.hasNext()) {
            fw4 fw4Var = (fw4) it.next();
            if (list3.contains(new tz9(fw4Var.a.v())) && !fw4Var.a.l()) {
                oz9Var = oz9.BOOKMARKED;   // 任一选中页未书签 → BOOKMARKED
            }
        } else {
            oz9Var = oz9.UNBOOKMARKED;     // 全部已书签 → UNBOOKMARKED
        }
    }
} else {
    oz9Var = oz9.UNBOOKMARKED;
}
List listL0 = m18.l0(u5j.s(x09Var, list3, null, null, oz9Var, 6));
dof dofVar = de2Var.O;
this.J = 2;
if (x82.I(m1dVar, listL0, dofVar, iw3Var, this) == ii2Var) {
    return ii2Var;
}
```

单页语义（Harmony 编辑器每次只作用于当前选中页）：选中页未书签 →
BOOKMARKED，已书签 → UNBOOKMARKED，即 `next = !current.bookmarked`。

### u5j.s —— 仅写字段 3（oz9）的 ModifyPage

`defpackage/u5j.java:1141`：

```java
public static ge8 s(x09 x09Var, List list, Integer num, m2d m2dVar, oz9 oz9Var, int i) {
    lxc lxcVarA = null;
    if ((i & 2) != 0) { num = null; }      // 掩码位 2 → 不带位置
    if ((i & 4) != 0) { m2dVar = null; }   // 掩码位 4 → 不带背景
    if ((i & 8) != 0) { oz9Var = null; }   // 掩码位 8 → 不带书签
    ...
    return r0j.a(list, lxcVarA, m2dVar, oz9Var);
}
```

掩码 `6 = 2|4` → `num`/`m2dVar` 置 null、`oz9Var` 保留：op 只携带
oz9 书签寄存器写入（对应 FlatBuffer ModifyPage 字段 3，与
`haj.a`/CreatePage 字段 3 同一编码位）。

### x82.I —— 日志通道接受 eof 策略

`defpackage/x82.java:174`：

```java
public static final Object I(m1d m1dVar, List list, eof eofVar, Map map, ef2 ef2Var) {
    ArrayList arrayList = new ArrayList(cu1.H0(list, 10));
    Iterator it = list.iterator();
    while (it.hasNext()) {
        arrayList.add(new wq9((cee) it.next(), null, false, null, 30));
    }
    return J(m1dVar, arrayList, eofVar, map, null, ef2Var, 8);
}
// J -> m1dVar.v0(eofVar, map2, ix4Var, new pq1(12, list), ef2Var)
```

### dof / cof —— eof 是撤销策略类型

`defpackage/dof.java`（全文）：

```java
public final class dof implements eof {
}
```

`defpackage/cof.java`（全文）：

```java
public final class cof implements eof {
    public static final cof a = new cof();
    public final String toString() { return "NotUndoable"; }
}
```

`eof` 即 undo-policy 接口：`dof`（空实现）= 可撤销，`cof` =
NotUndoable。`ae2` 书签分支传 `de2Var.O`（类型 `dof`）——原版书签
切换与旋转页（`zd2` case 1，同一 `x82.I` 通道、`dof` 同参）同级，
**是可撤销动作**。

## Harmony 缺口（修复前）

- `NotePage.toggleCurrentPageBookmark` →
  `PageRepositoryImpl.setPageBookmarked` →
  `persistOriginalPageBookmark`：落 ModifyPage op + reducer 物化
  `page_info.bookmarked`，但**不推 UndoableAction**，撤销栈无记录。
- 既有 `PAGE_SETTINGS`/`UPDATE_PAGE` 通道无法承载：
  `PageStructureOpCodec.samePageSettings` 刻意不含 `bookmarked`
  （ADR-0508 决策——书签是寄存器而非结构属性），书签唯一变更会被
  `classifyPageStructureMutation` 判为 "does not change state"。

## Harmony 对齐（本 Phase）

- `OpType.PAGE_BOOKMARK = 6`：持久历史 companion op（`NPBK` magic），
  载荷 `fromRevision/toRevision/pageId/bookmarkedBefore/After`，
  校验单步版本与寄存器翻转，拒绝尾随字节。
- `setPageBookmarked` 接受可选 `HistoryMetadata`：原版页路径
  `persistOriginalPageBookmark`（ModifyPage reducer 内
  `advanceStructureRevision`）后追加 companion 并校验版本 +1；
  legacy 页路径直写 `page_info` 后以同款 guard 自增版本再落
  companion；寄存器已是目标值时 fail-closed。
- `UndoableActionType.PAGE_BOOKMARK = 26` + `PageBookmarkAction`；
  `toggleCurrentPageBookmark` 构造动作→`preparePageAction`→带 history
  写仓储→`pushPageAction`；`applyPageHistory`/`validatePageActionState`
  新增分支按 before/after 重放并校验源寄存器值；
  `NoteCanvasView.isPageAction` 收录；`PersistentHistory` 物化
  companion 为 `PageBookmarkAction`（重启可恢复撤销栈）。

## 与原版差异

- 原版 op 流内 `u5j.s` ModifyPage 本身即历史单元（x82.I 记日志）；
  Harmony 把同步 op（ORIGINAL_MODIFY_PAGE，无 history 标记）与本地
  历史 companion（PAGE_BOOKMARK）分行——与 DUPLICATE_PAGE /
  DELETE_PAGE_COMPENSATION 的既有 companion 架构一致。
- 原版 ae2 支持多页选中（任一未书签→全部 BOOKMARKED）；Harmony 编辑器
  单页操作，多选页管理为已登记独立差异项，不在本 Phase 范围。
