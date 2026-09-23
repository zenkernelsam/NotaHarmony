# 原版证据：面板页操作不移动查看页 + 批量 Duplicate 锚定（JADX，decompiled_1.0.3）

Phase 650 的原版依据。类文件均取自
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\`。

## 1. 批操作从不写 UiState（ae2 / e2 全文零 qd2 引用）

`qd2` 是 content-manager 的 UiState（`currentPageIndex` 为字段 a）。
对 `ae2.java`（批量 Bookmark/Clear/Copy/Cut/Delete/Duplicate 变体
0..5）与 `e2.java`（Paste 协程）全文检索 `qd2`：**0 命中**。

→ 所有面板发起的页操作完成时**不移动查看页**；查看页跟随
`qd2.a` 原值（原页表索引不变）。

对比：`de2.java` 仅 4 处 qd2 引用——`s()`（搜索 query）、`u()`
（退出复位）、`t()`（context resolver）、`l()`（选择态）——
无一是页操作路径。

## 2. 批量 Duplicate 的单一锚点（ae2 v5 + de2.j）

`ae2.java` default 分支（variant 5，Duplicate）：

```java
ArrayList arrayListE3 = u5j.e(x09Var4, list);            // 每页拷贝 op
cxc cxcVarJ = de2.j(de2Var, x09Var4, list);              // 锚点页键
if (cxcVarJ != null) {
    m1dVar5.c0(x09Var4, arrayListE3, cxcVarJ, dofVar5, iw3.I, this);
}
```

`de2.java:134-149` `j()`：从页表末尾向前扫描，返回**第一个属于
选中集的页**——即「页序上最后一张选中页」：

```java
ListIterator listIterator = list2.listIterator(list2.size());
do {
    if (!listIterator.hasPrevious()) { objPrevious = null; break; }
    objPrevious = listIterator.previous();
} while (!list.contains(new tz9(((fw4) objPrevious).a.v())));
```

→ 全部副本经一次 `c0` 应用插入在**选中集末页之后**，而非各自
源页之后。拷贝序 = `au1.T1(selectedPageIds)` 的页序排序。

## 3. Add Page 仅 cell 菜单可达（zd2 无其它实例化点）

全源检索 `new zd2(`：仅 `fd2.java` case3（v0=add）与 default
（v1=rotate）及 `zd2.create` 自身。`feature_note__content_manager_add_page`
字符串/图标仅 `n9j.java`（cell 菜单）引用。

`zd2.invokeSuspend` 未反编译（416 指令跳过）——其内部是否写
`qd2` 静态不可判。推定不导航的依据：

- 同签名姊妹变体 v1（rotate）已证不导航（Phase 634）；
- 面板为管理面：加页后跳页会脱离管理上下文；
- 若 zd2 写 qd2，需经 `de2Var.T`（StateFlow）——de2 全部公开
  方法中无一在页操作后写该槽位。

残余歧义（pager 是 raw-index 还是 keyed identity）登记 ADR-0617。

## 4. 删除路径的既有对照

`de2.i`（delete 构造器，`de2.java:119-131`）：收集页内元素键 →
`u5j.l` 删除 op（掩码 10）+ `list2.size() - list.size() < 2` 时
补 `u5j.i` 末位插空页。`ae2` v4 应用后 `v7d.emit(od2.a)`
（snackbar 事件）——仍无 qd2 写。

Harmony `deletePageAt`（Phase 647）已按页键保持查看页
（`selectedAfter = selectedBefore`，非当前页）——同一约定。

## 5. Harmony 映射（Phase 650）

| 原版 | Harmony |
|---|---|
| ae2/e2 不写 qd2 → 查看页不动 | `addPageAt`/`duplicatePageAt`/`pasteCopiedPageAt` 取消 `selectPageById(新页)`/`currentPageIndex=insertIndex`，改为 `selectPageById(selectedBefore)` |
| de2.j 锚点=选中集末页 | 批 `duplicate`：`anchorIndex = indices[last]` 起，逐 payload `pasteOneCopiedPage` 顺次后插 |
| u5j.e 按选中序产拷贝 op | 升序遍历 `indicesOf()`（`dispatchSelection` 已按页序上抛） |
| zd2 面板独占 add | Harmony 底栏 "+"（超集面）与 cell 菜单共用同一不导航语义 |
