# 原版批操作历史语义证据（JADX，2026-09-23）

## 结论

原版 Notability 1.0.3 的页面批操作（多选工具条 `tfh` → `n9j` 的 `tc2`
dispatch → `ae2` 变体）对**整个批**只调用一次 `x82.I`，即一次操作应用、
一步撤销。Harmony 此前逐页入栈（每页一条历史），批操作需要 N 次撤销
才能回滚 —— 这是 Phase 651 要关闭的登记分歧。

## 证据明细

`decompiled_1.0.3/sources/defpackage/ae2.java`（`invokeSuspend` 五个 case）：

- **case 0（Bookmark）**：遍历 `list3`（选中页集）收集 op →
  `List listL0 = m18.l0(u5j.s(x09Var, list3, null, null, oz9Var, 6))` →
  单次 `x82.I(m1dVar, listL0, dofVar, iw3Var, this)`。
- **case 1（Clear）**：`while (it2.hasNext())` 把每张选中页的 element
  keySet 累进 `arrayList` → `List listL1 = m18.l0(u5j.l(x09Var2,
  arrayList, null, 14))` → 单次 `x82.I(m1dVar2, listL1, dofVar2, …)`。
- **case 2/3/4**：同一模式——先构造覆盖**全部**选中页的 op 表
  （`m18.l0(u5j.…)`），再仅一次 `x82.I`。

`ae2.java` 全文 `x82.I(` 出现 ≤5 次（每个变体至多一次），且不存在按页
循环调用 `x82.I` 的结构 —— 批操作在上游就是**单条目历史**。

`decompiled_1.0.3/sources/defpackage/x82.java`：

```java
public static final Object I(m1d m1dVar, List list, eof eofVar, Map map, ef2 ef2Var) {
    ArrayList arrayList = new ArrayList(cu1.H0(list, 10));
    Iterator it = list.iterator();
    while (it.hasNext()) {
        arrayList.add(new wq9((cee) it.next(), null, false, null, 30));
    }
    return J(m1dVar, arrayList, eofVar, map, null, ef2Var, 8);
}
// J → m1dVar.v0(eofVar, map2, ix4Var, new pq1(12, list), ef2Var)
```

`x82.I` 把整张 op 表包成 `wq9` 项后，以单个 `pq1(12, list)` 交给
`m1dVar.v0` 应用 —— 历史侧只记录**一个**复合条目，Undo 一次回滚整批。

## 对照：Harmony 既有模型

`UndoRedoManager.peekGroup()` 原本仅支持**同页**元素条目的时间窗归并
（INSERT_TEXT / REMOVE_TEXT / CREATE_INK），跨页条目无法同组。
Phase 651 新增显式批轨 `PAGE_BATCH`：派发窗口内所有子操作共享
`actionTime`（批次标识，单调递增），`peekGroup` 按
`noteId + PAGE_BATCH + actionTime` 跨页归并；消费端每次
`performHistory` 只应用+提交一个子条目，`continuePageBatch` 自动驱动
剩余子条目（跨页经 `pendingHistoryDirection`/`resumePendingHistory`
衔接），直到同批耗尽 —— 对用户等价于原版的「一次撤销」。
