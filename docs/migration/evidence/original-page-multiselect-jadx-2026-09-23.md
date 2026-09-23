# 原版证据：页面管理面板多选模式（JADX，decompiled_1.0.3）

Phase 648 的原版依据。类文件均取自
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\`。

## 1. 选择状态字段（qd2.UiState）

`qd2.java:149` toString 按字段序给出：

```
UiState(currentPageIndex=a, pages=b, thumbnails=c, selectedFilter=d,
        isSelecting=e, selectedPageIds=f, isSearchActive=g,
        searchQuery=h, searchMatchingPageKeys=i)
```

`qd2.a(...)` 的 copy 参数按同一字段序排列，位掩码置位=保留旧值。

## 2. 选中集成员切换（fd2 case0）

`fd2.java:29-38`：

```java
case 0:
    cxc cxcVar = pd2Var.a;
    do {
        value = asdVar.getValue();
        qd2Var = (qd2) value;
        zContains = qd2Var.f.contains(new tz9(cxcVar));
        set = qd2Var.f;
    } while (!asdVar.i(value, qd2.a(qd2Var, null, null, null, null,
        false, zContains ? ys2.G(set, new tz9(cxcVar))
                         : ys2.K(set, new tz9(cxcVar)),
        false, null, null, 479)));
```

掩码 479 = 511-32，仅写字段 5（selectedPageIds）：`ys2.K` 并入 /
`ys2.G` 移出。**不改 isSelecting**——选中集非空即驱动选择 UI。

cell 侧接线（`id2.java:137`）：`new fd2(de2Var, pd2Var, 0)` 作为
cell 点击回调之一；`id2:126-127` 同时读 `qd2.e`（isSelecting）与
`f.contains(key)` 渲染勾选态。

## 3. "Select" 菜单项（s8 case1）

`s8.java:51-58`：`apb.f` 菜单项，文案
`R.string.feature_note__content_manager_select`，点击 `function0`
（即 fd2 case0 回调）。宿主 `q8.java:66` 把它挂在 cell 的 `apb.d`
溢出菜单内（`z ? 1 : 0` 选择文案项或图标项）。

## 4. 退出/全选/取消全选（de2.u + n9j function9）

`de2.java:331-338` `u()`：

```java
qd2.a((qd2) value, null, null, null, null, false, qw3.I, false,
      null, null, 463)
```

掩码 463 = 511-48 清位 4/5/6 → `isSelecting=false`、
`selectedPageIds=qw3.I`（空集）、`isSearchActive=false`——一次写
回三个字段。

`n9j.java` function9 4-case 分发（i=0..3）：

| case | 行为 |
|---|---|
| 0 | `!qd2.g` → `de2.l()` 激活搜索；否则 query 复位 ""（搜索回退） |
| 1 | `qd2.a(..., true, qw3.I, false, ..., 463)` → isSelecting=true + 清空选中集 + 关搜索（进入选择态） |
| 2 | `selectedPageIds = au1.X1(qd2.c() 过滤全集)` → Select all |
| 3 | `selectedPageIds = 空` + `de2.u()` → Deselect all 并退出 |

## 5. 批量操作分发（n9j tc2 7-case）

`n9j.java:676+` 每个 case 取 `au1.T1(((qd2) gl8.getValue()).f)`
（选中集排序为 List）后分发：

| case | 调用 | 退出选择态 |
|---|---|---|
| 0 | `de2.o(list)` Copy | 是（随后 `u()`） |
| 1 | `de2.r(list)` Duplicate | 否 |
| 2 | `de2.q(list)` Delete | 是 |
| 3 | `de2.p(list)` Cut | 是 |
| 4 | `e2(16)` Paste | 否 |
| 5 | `de2.m(list)` Bookmark | 否 |
| 6(default) | `de2.n(list)` Clear | 否 |

`de2.m~r` 全部对空集 fail-closed 并打 MODEL 日志
（`"Bookmark toggle with empty page selection"` 等），非空则
`xj2.A(..., new ae2(this, list, null, v))`——批操作经 ae2 变体
0..5 应用到 `x82.I` 记帐通道（整批一条 op 流应用）。

## 6. 选择工具条（tfh.a）

`tfh.java`：溢出菜单（`apb.d`）内

- z2 ? `content_manager_deselect_all` → function4
  : `content_manager_select_all` → function3；
- z7 组：`content_manager_cut`→f5、`content_manager_paste`→f6
  （z3 门控）、`content_manager_bookmark`→f7、
  `content_manager_clear_page`→f8（z6 启用门控）。

头部另有 f0/f1(/f2) 图标位（uth.a/uth.b/s01 内容槽）。

## 7. 多页剪贴板（mg2/dg2）

`dg2.java`：`CopiedPagesData(ops: ArrayList, pageCount: int)`——
页剪贴板本就是**多页有序记录**；`mg2.b` 持有一份进程级实例。

## 8. Harmony 映射（Phase 648）

| 原版 | Harmony |
|---|---|
| fd2 case0 成员切换 | `PageOverviewPanel.toggleSelectPage(pageId)` |
| s8 case1 "Select" 菜单项 | cell 上下文菜单末项 `pages_menu_select` |
| n9j case1 进入选择态 | 选中集非空 → `selecting=true` |
| n9j case2 Select all | `selectAllVisible()`（`visibleItems()` = qd2.c() 等价物） |
| n9j case3 Deselect all | 清空 + `exitSelection()` |
| de2.u() 退出 | `exitSelection()`：selecting/selectedPageIds/searchActive 三字段复位 |
| tc2 case0..6 批操作 | `dispatchSelection` → `onSelectionAction` → `dispatchPageSelectionAction` |
| tc2 退出语义 | copy/delete/cut 后 `exitSelection()`；duplicate/bookmark/paste/clear 保持 |
| dg2 多页剪贴板 | `copiedPages: CopiedPagePayload[]` + `storeCopiedPages`/`copiedPagePayloads` |
| e2 v16 批粘贴 | `pasteCopiedPageAt` 逐 payload 顺次插运行锚点后 |
| tfh 工具条 | 面板内横向滚动 chip 行（选择态渲染） |
