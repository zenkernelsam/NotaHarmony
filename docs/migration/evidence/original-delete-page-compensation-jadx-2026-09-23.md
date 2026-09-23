# 原版证据：末页删除补偿（de2.i 同流补插空白页） — Phase 638

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。
`de2.i` / `ae2` / `u5j` 均正常反编译，直接引用。

## de2.i：删除 op 流内联补偿（de2.java:116-131）

```java
public static final th7 i(de2 de2Var, x09 x09Var, List list) {
    th7 th7VarS = m18.S();
    ArrayList arrayList = new ArrayList();
    Iterator it = list.iterator();
    while (it.hasNext()) {
        au1.O0(arrayList, ((a79) x09Var).j.m(((tz9) it.next()).a).keySet());
    }
    th7VarS.add(u5j.l(x09Var, arrayList, list, 10));           // ① 删页 op（delete-entities）
    List list2 = ((a79) x09Var).i;                             // ② 笔记当前页表
    if (list2.size() - list.size() < 2) {                      // ③ 删除后不足两页
        th7VarS.add(u5j.i(x09Var, list2.size() - 1, 0, 14));   // ④ 同流补插一张空白页
    }
    return m18.E(th7VarS);                                     // ⑤ 单 op 流返回 = 单个撤销单元
}
```

语义要点：

- `list2 = x09.i`：笔记页表；`list`：被删页集合。`size() - list.size() < 2`
  ⇔ 删后剩余不足 2 页。单页删除下 ⇒ 笔记页数 ≤ 2 时触发补偿。
- 补偿页经 `u5j.i`（同 Phase 637 Add Page 的 op 构造器）：插入下标
  `list2.size() - 1` = 构建时的**末页边界**。对单页删除的三种情形逐一
  验证落点（op 流先删后插）：
  - `[A]` 删 A → 下标 0 处插入 → `[comp]`；
  - `[A,B]` 删 A → 下标 1 = B 的槽位边界 → 删除生效后 `[comp,B]`，
    comp 落受害页槽位（0）；
  - `[A,B]` 删 B → 下标 1 → `[A,comp]`，comp 落受害页槽位（1）。
  即**补偿页恰好占据受害页槽位**，笔记页数不变、永不为零。
- `haj.a(anchor, null, 1, oz9.UNBOOKMARKED, 16)`（`u5j.java:667-677`）：
  补偿页 **null nz9（继承笔记默认背景）+ UNBOOKMARKED + 单页**——
  与 Add Page 产出的页描述符完全同型。
- `th7VarS.add(删页 op)` 先于 `th7VarS.add(补偿 op)`，`m18.E` 封包为
  一条 op 流——删除 + 补偿是**单个撤销单元**；撤销该流即恢复受害页并
  撤去补偿页，重做反之。

## 派发链：删除入口

- `ae2.java` case 4（plain delete 协程，`ae2.java:275-285`）：
  `th7 th7VarI2 = de2.i(de2Var, (x09) k1aVar5.J, list);`
  `x82.I(m1dVar4, th7VarI2, dofVar4, iw3Var, this)` —— 单事务应用。
- `ae2.java` case 3（Cut，`ae2.java:232-243`）：先把选中页经
  `u5j.e` 序列化写入 `mg2.b`（页剪贴板，Phase 636），随后同样调用
  `de2.i` —— **Cut 的删除也携带补偿语义**。

## Harmony 对齐（Phase 638）

- `NotePage.deleteCurrentPage` 不再以 `pages.length <= 1` 阻塞；
  `orderBefore.length <= 2` 时走补偿路径。
- `PageRepositoryImpl.deletePageWithCompensation` 单事务：先写
  `page_delete_checkpoint`（受害页 PageInfo + 元素 + 检索行），原版
  路径 `persistOriginalPageVisibility(victim, true)` +
  `persistOriginalCreatePage(anchor = before[size-2])`，legacy 路径
  `physicalDeletePage` + `insertPageInfoAt(victimIndex)`；落点校验
  fail-closed，随后追加 `DELETE_PAGE_COMPENSATION` companion op。
- 撤销/重做：`undoDeletePageWithCompensation`（复原受害页 + 移除
  补偿页）与 `redoDeletePageWithCompensation`（再删受害页 + 复原
  补偿页）各自在同一事务内完成并追加同型 companion（UNDO/REDO
  effect），任何一步失败整体回滚。
- 持久历史：`OpType.DELETE_PAGE_COMPENSATION = 5`（新 companion
  op 类型），`DeletePageCompensationOpCodec`（magic `DCP1`）编码
  `fromRevision/toRevision/deletedPageId/insertedPage(PageInfo 全字段)/
  pageOrderBefore/pageOrderAfter`，校验器接受 PUSH/REDO 正向与 UNDO
  反向两种序对，拒绝非同槽位换页、空 id、越界 pageIndex、尾字节。
  `PersistentHistory.materializeAction` 物化为带 `compensationPage`
  的 `DeletePageAction`，复用既有 `page_delete_checkpoint` 内容快照。
- UI：`DeletePageAction.compensationPage` 可选字段；
  `applyDeletePageCompensationHistory` 撤销=移除补偿页+恢复受害页，
  重做=删受害页+补回补偿页；`isDeleteCompensationTransition` 校验
  "同槽位一对一换页"；`PageManagerBar` 移除 `pageCount > 1` 门
  （原版删除入口不因页数禁用）。

## 结论

原版删除页在删后不足两页时**同一 op 流内补插一张空白页**（落在受害
页槽位、继承笔记默认背景、无书签），删除永不阻塞、笔记永不为零页，
且整个组合是单个撤销单元。Harmony Phase 638 以
`DELETE_PAGE_COMPENSATION` companion + 单事务仓储 API + 同型 UI
撤销/重做实现等价语义；Cut（Phase 636）复用同一删除路径，自动获得
补偿行为。
