# 原版证据：内容管理器 Add Page → 选中页后插入 — Phase 637

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。
`zd2.invokeSuspend` 的 JADX 结构化输出失败，其调用帧取自
`jadx --single-class defpackage.zd2 --comments-level debug` 指令级转储，
并与已正常反编译的 `id2`/`fd2`/`n9j`/`u5j` 逐一互证。

## 菜单派发链

- `n9j.java:1968-1976`：菜单首项
  `R.string.feature_note__content_manager_add_page` +
  `R.drawable.ui_designsystem__add_page`，onClick 绑定
  `n9j.c` 的 `function0` 参数（`Function0 function9 = function0`）。
- `n9j.java:2442`（`n9j.g` 调 `n9j.c`）：
  `c(..., function3, function4, ..., function11, ...)` ——
  `n9j.c` 的 `function0..function8` 分别取自 `n9j.g` 的
  `function3..function11`。
- `id2.java:170`：`g.function3 = new fd2(de2Var, pd2Var, 3)`。
- `fd2.java:46-49` case 3：
  `xj2.A(de2Var.M, null, null, new zd2(de2Var, cxcVar2, null, 0), 3)`。
- 即 **Add Page = `zd2` 协程变体 0**（变体 1 为 Rotate Page，
  见 `original-page-rotate-jadx-2026-09-23.md`——该文档旧注
  "变体 0 = duplicate" 系笔误，duplicate 实为 `fd2` case 7 →
  `de2.r` → `ae2` 变体 5，见 Phase 635 证据）。

## zd2.invokeSuspend 变体 0（指令转储）

```java
k1a ctx = de2.k(de2Var, this);              // (m1d, x09) 笔记上下文
m1d r3 = ctx.I; x09 r1 = ctx.J;
r12 = 0;
for (fw4 page : ((a79) r1).i)                // 遍历文档页
    if (ba6.o(page.a.v(), r9)) break;        // mz9.v() == 选中页 cxc
    else r12++;
if (未命中) r12 = -1;
r12 = r12 + r7;                              // r7 = 1 → 选中下标 + 1

ln2 op = u5j.i(r1, r12, r11=0, r9=14);       // 在选中页后插入
th7 ops = m18.S(); ops.add(op);
x82.I(r3, m18.E(ops), r8.O, r2, this);       // m1d.c0 派发应用
```

## u5j.i：按下标生成插入 op（u5j.java:667-677）

```java
public static ln2 i(x09 x09Var, int i, int i2, int i3) {
    if ((i3 & 4) != 0) {
        i2 = 1;                              // mask 14 → i2 = 1（单页）
    }
    f1a f1aVar = ((a79) x09Var).f;
    cxc cxcVarB = bfj.b(f1aVar.b, i, f1aVar.h); // 下标 i 处序列锚点
    return haj.a(cxcVarB, null, i2, oz9.UNBOOKMARKED, 16);
}
```

- `bfj.b(pages, i, h)`：为插入下标 `i` 解析序列位置锚点（fractional
  index）；`r12 = 选中下标 + 1` ⇒ **新页紧随选中页**。
- `haj.a(anchor, null, 1, oz9.UNBOOKMARKED, 16)`：`ln2` 页描述符携带
  **null nz9** —— 新页无自有背景寄存器，继承笔记默认背景
  （与 Duplicate 的 `wz9.u` 有效背景复制路径不同）；bookmark 恒
  `UNBOOKMARKED`；页数 1。

## 与 de2.i 删除补偿的对照

`de2.i`（删除页 op 构造）在 `list2.size() - list.size() < 2` 时追加
`u5j.i(x09Var, list2.size() - 1, 0, 14)` —— 删除到不足 2 页时于
`size - 1` 处补一张空页，即原版不阻塞删除而是**保证笔记始终有页**。
Harmony 当前以 `pages.length <= 1` 阻塞末页删除，该差异登记为
后续 Phase 候选（不在本 Phase 范围）。

## 结论

原版 Add Page = 在**选中页之后**插入一张继承笔记默认背景、无书签的
新页，非尾部追加。Harmony Phase 637 起 `addPage` 以当前页为序列锚点
（`persistOriginalCreatePage(afterPageId)` → `readPageIdentity`），
legacy 路径按 `page_index` 倒序平移腾位，落点 = `anchorIndex + 1`。
