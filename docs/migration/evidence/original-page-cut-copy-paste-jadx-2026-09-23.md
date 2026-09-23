# Evidence — Original Page Cut / Copy / Paste（JADX，1.0.3）

Phase 636 证据锚点：`decompiled_1.0.3/sources/defpackage/`。

## 菜单面（n9j.java ~1968-2083）

单页上下文菜单的原始顺序：

| 序 | R.string | 动作 |
|---|---|---|
| 1 | `content_manager_add_page` | Add Page |
| 2 | `content_manager_cut` | Cut |
| 3 | `content_manager_copy` | Copy |
| 4 | `content_manager_paste` | Paste（仅剪贴板非空） |
| 5 | `content_manager_duplicate` | Duplicate |
| 6 | `content_manager_rotate_page` | Rotate Page |
| 7 | `content_manager_create_template` | Create Template（`INTERNAL_USERS_ONLY`） |
| 8 | `content_manager_clear_page` | Clear Page |

Paste 的可见性由 `de2.java:54` 的 `bsd.a(Boolean.valueOf(mg2Var.b != null))` 绑定——剪贴板非空才出现。

## 派发链（de2.java:173-230）

| 方法 | ae2 变体 | 语义 | 空选日志 |
|---|---|---|---|
| `de2.m` | 0 | Bookmark toggle | "Bookmark toggle with empty page selection" |
| `de2.n` | 1 | Clear pages | "Clear pages with empty page selection" |
| `de2.o` | 2 | **Copy pages** | "Copy pages with empty page selection" |
| `de2.p` | 3 | **Cut pages** | "Cut pages with empty page selection" |
| `de2.q` | 4 | Delete pages | "Delete pages with empty page selection" |
| `de2.r` | 5 | Duplicate pages | "Duplicate pages with empty page selection" |

## ae2 case 2 — Copy（ae2.java:190-205 区域）

```java
ArrayList arrayListE = u5j.e((x09) k1aVar3.J, list);
if (!arrayListE.isEmpty()) {
    mg2 mg2Var = de2Var.P;
    dg2 dg2Var = new dg2(list.size(), arrayListE);
    mg2Var.b = dg2Var;
    asd asdVar = de2Var.X;
    asdVar.k(null, Boolean.TRUE);
}
```

`u5j.e` 产出与 Duplicate 完全相同的页负载流（wz9.u：有效 nz9 +
`l7j.c` 单页 PDF 折叠 + `oz9` bookmark 入 `haj.a` field 3）。序列化结果
**整段存入进程级页剪贴板** `mg2.b`——`dg2.toString()` 自证
`CopiedPagesData(ops=…, pageCount=…)`。

## ae2 case 3 — Cut（ae2.java:206-244 区域）

与 Copy 相同的两步（序列化 → `mg2Var2.b = dg2Var2`），随后：

```java
th7 th7VarI = de2.i(de2Var, x09Var3, list);
dof dofVar3 = de2Var.O;
x82.I(m1dVar3, th7VarI, dofVar3, iw3Var, this);
```

`de2.i` 构造的删除 op 与 Delete Pages（case 4）同源——即原版 Cut 的
持久日志就是"删除所选页"，撤销语义 = 恢复删除页。剪贴板记录保留在
`mg2.b` 供后续 Paste。

## Paste 应用侧

`mg2`/`dg2` 仅被 `ae2`/`de2`/`lg2` 触碰；`lg2`（fvb+gc9+mg2+dof+g39）
是统一的剪贴板应用器（元素剪贴板 `mg2.a:cg2` 与页剪贴板 `mg2.b:dg2`
并存于同一 mg2 实例），经 `m1d.c0`/`x82.I` 转码应用——与 Duplicate
共用同一条 op 转码通道，因此原版日志中 Paste 与 Duplicate 产出的
op 族完全相同（CreatePage + 实体创建 ops，全新身份）。

## Harmony 对应

| 原版 | Harmony |
|---|---|
| `mg2.b` 进程级页剪贴板 | `rendering/OriginalPageClipboard.ets`（`copiedPage` 单例） |
| `dg2` CopiedPagesData | `CopiedPagePayload { noteId, sourcePageId, background, bookmarked, plan }` |
| `u5j.e` 序列化 | `captureCurrentPageCopyPlan`（元素快照 + 页内组子图） |
| `de2.i` 删除 ops（Cut） | 既有 `deleteCurrentPage`（DELETE_PAGE 行动） |
| `m1d.c0` 转码应用 | `insertCopiedPage` + `commitCopiedPageContent` |
| `mg2.b != null` 门 | `canPastePage`（`copiedPagePayload() !== null`） |

结构性差异（已记录）：
- 原版剪贴板存 op 流；Harmony 存物化负载（背景 + 元素计划），粘贴时经
  同一转码重放——对外语义一致（全新实体身份、同型日志）。
- 跨笔记粘贴仅允许无图片页：图片元素引用按笔记链接的内容寻址资产行，
  跨笔记写入需补资产链接行（后续项），含图页跨笔记 fail-closed。
