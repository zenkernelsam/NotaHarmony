# 原版证据：内容管理器 Duplicate → 页复制 op 流（CreatePage + 实体转码）— Phase 635

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。
`ae2`/`de2`/`u5j`/`wz9`/`l7j` 均正常结构化反编译，关键行逐一引用。

## 菜单派发链

- `n9j.java:2022-2023`：菜单项
  `R.string.feature_note__content_manager_duplicate` +
  `R.drawable.ui_designsystem__duplicate`。同段菜单尚有
  `feature_note__content_manager_create_template`，但该入口由
  `lc4.a(ac4.w0)`（INTERNAL_USERS_ONLY feature flag）门控，
  生产 1.0.3 中不可见（见 Phase 635 报告）。
- `de2.java:223-230`：`public final void r(List list)`——空选区时仅
  `a.c(yn7.MODEL, "Duplicate pages with empty page selection", …)` 打日志
  返回；否则 `xj2.A(this.M, null, null, new ae2(this, list, ef2Var, 5), 3)`
  启动 `ae2` 协程**变体 5**（同分发器变体 0/1/2/3/4 分别为
  clear/copy/cut/其他页操作，de2.java:179-229 五连派发）。

## ae2 变体 5（ae2.java:307-325）

```java
this.J = 1;
objK5 = de2.k(de2Var, this);                 // (m1d, x09) 笔记上下文
k1a k1aVar6 = (k1a) objK5;
m1d m1dVar5 = (m1d) k1aVar6.I;               // 引擎/转码器
x09 x09Var4 = (x09) k1aVar6.J;               // 文档
ArrayList arrayListE3 = u5j.e(x09Var4, list);// ① 选中页 → op 流
cxc cxcVarJ = de2.j(de2Var, x09Var4, list);  // ② 插入锚点
if (cxcVarJ != null) {
    dof dofVar5 = de2Var.O;
    this.J = 2;
    m1dVar5.c0(x09Var4, arrayListE3, cxcVarJ, dofVar5, iw3.I, this);
}                                            // ③ 转码应用
```

## u5j.e：页序列化（u5j.java:417-…）

- 遍历文档实体表 `th7VarA`（`b.a(a79Var)`），按选中页集合
  `au1.X1(collection)` 过滤，`b.e(...)` 命中者进入 `arrayList`。
- `u5j.java:527`：每页经 `wz9Var.u(aVar)` 产出页负载——即 CreatePage
  语义的页描述（`wq9`），不是 ModifyPage。

## wz9.u：页负载 = 有效 nz9 + PDF 单页折叠 + bookmark（wz9.java:142-157）

```java
public final qo5 u(a aVar) {
    nz9 nz9VarB;
    sw9 sw9Var = this.k;                     // 页 PDF 寄存器
    if (sw9Var != null) {
        sw9 sw9VarC = l7j.c(sw9Var, this.m, ((mmf) this.g.K).I);
        //                 ^cropBoxes 下标    ^wz9.F()=pageInAsset
        nz9 nz9VarB2 = B();                  // 有效背景（register ?? note 兜底）
        nz9VarB = nz9VarB2 != null ? m18.O(nz9VarB2, sw9VarC, null, null, 29)
                                  : null;    // 只替换 pdf 字段
        if (nz9VarB == null) { nz9VarB = B(); }
    } else {
        nz9VarB = B();                       // 非 PDF 页：有效 nz9 原样携带
    }
    return a.b(aVar, haj.a(null, nz9VarB, 1, (oz9) this.f.K, 16),
               null, this.i, null, 10);
    //              ^页身份(cxc)    ^oz9 = bookmark 寄存器
}
```

要点：复制负载携带的是**有效**背景（`B()` = 页 register ?? 笔记兜底），
不是仅页本地 register；PDF 页先经 `l7j.c` 折叠为单页消费
（pagesConsumed=1, pageOffset=pageInAsset, cropBoxes 只留本页项），
bookmark 随 `oz9` 寄存器一并序列化。

## de2.j：插入锚点 = 最后一个选中页（de2.java:134-150）

```java
ListIterator listIterator = list2.listIterator(list2.size());   // 文档页表
do {
    if (!listIterator.hasPrevious()) { objPrevious = null; break; }
    objPrevious = listIterator.previous();                      // 逆序遍历
} while (!list.contains(new tz9(((fw4) objPrevious).a.v())));
fw4 fw4Var = (fw4) objPrevious;
if (fw4Var != null) { return fw4Var.a.v(); }                    // cxc 页身份
return null;
```

逆序找最后一个选中页作为 `cxc` 锚点——`m1d.c0` 把 op 流插入该锚点之后。
单页复制语义即"副本紧随源页"。

## 身份语义

`m1d.c0` 的转码路径（`c.c`/`qee` 系）为流内每个实体签发全新操作身份；
Harmony 复用剪贴板转码的 `mappedIds` 重发机制与之等价
（`docs/migration/evidence/original-paste-source-z-index-2026-09-28.md`
同族机制）。

## Harmony 对齐点

| 原版 | Harmony |
|---|---|
| `u5j.e` 页负载 `wz9.u` | `duplicatedOriginalPageBackground`（有效 nz9 + `collapsedOriginalPagePdf`）|
| `wz9.u` → CreatePage（wq9） | `persistOriginalDuplicatePage` → `encodeOriginalLocalCreatePage(source, null, null, 1, background)` |
| `de2.j` 锚点 | `CreatePage.location = 源页身份`（插入其后）|
| `m1d.c0` 实体转码（全新身份） | `commitOriginalDuplicatePageContent` → `transcodeOriginalPageElements`（mappedIds）|
| 无包裹 Group（逐实体 op） | `validateOriginalDuplicatePageContentPlan` 允许空组图 |
| `haj.a` field 3 = `oz9` bookmark | `encodeOriginalLocalCreatePage(..., bookmarked)` 写 ln2 field3=1；`persistOriginalDuplicatePage` 透传源页 `bookmarked` |

书签为完全对齐：原版把源页 `oz9` 寄存器序列化进 ln2 负载
（`haj.a(null, nz9, 1, (oz9) this.f.K, 16)` → `aVarA.c(3, oz9.I, 0)`），
Harmony 副本页经同一 field3 继承——复制已书签页产出已书签副本。
