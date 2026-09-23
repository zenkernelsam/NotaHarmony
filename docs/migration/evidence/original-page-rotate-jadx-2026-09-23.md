# 原版证据：内容管理器 Rotate Page → 页级 ModifyPage 背景寄存器 — Phase 634

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。
`zd2.invokeSuspend` 的 JADX 结构化输出失败，本节 rotate 流程证据取自
`jadx --single-class defpackage.zd2 --comments-level debug` 的指令级转储
（`Notability_1.0.3/com.gingerlabs.notability.apk`），关键调用帧逐一与
已正常反编译的类互证。

## 菜单派发链

- `n9j.java:2039`：菜单项 `R.string.feature_note__content_manager_rotate_page`
  + `R.drawable.ui_designsystem__rotate_page`，回调 `function5`
  （`n9j.c` 第 5 个 Function0）。
- `n9j.g` → `n9j.c` 参数映射：`c.function5 = g.function8`。
- `id2.java` → `g.function8 = fd2(de2, pd2, 8)` → `fd2` default 分支
  `xj2.A(de2.M, …, new zd2(de2, cxc, null, 1), 3)`。
- 即 Rotate Page = `zd2` 协程变体 1（变体 0 为同一分发器上的 Add Page，
  经 `fd2` case 3 派发并在选中页后 `u5j.i` 插入，见
  `original-add-page-anchor-jadx-2026-09-23.md`；本行旧注误记为
  duplicate——duplicate 实为 `fd2` case 7 → `de2.r`）。

## zd2.invokeSuspend 变体 1（指令转储）

```java
k1a ctx = de2.k(de2Var, this);              // (m1d, x09) 笔记上下文
for (fw4 page : a79(x09).i)                  // 找到选中页 mz9
    if (ba6.o(page.a.v(), r9)) break;
nz9 r7 = page.a.B();                         // 有效背景（register ?? note 兜底）
if (r7 == null) return;                      // null 早退

// cl4.a = π（pce lazy: ra case 29 → Float(3.1415927)）；
// cl4.a(f,g) = |f-g| < 1e-4
float r12 = r7.m();                          // 当前 rotation
float r13;
if (cl4.a(r12, 0))      r13 = cl4.a.value / 2.0f;      // 0   → π/2
else if (cl4.a(r12, V/2)) r13 = V;                     // π/2 → π
else if (cl4.a(r12, V))   r13 = 1.5f * V;              // π   → 3π/2
else                      r13 = 0;                     // 3π/2 及任意非基数 → 0

nz9 r12' = m18.O(r7, null, Float(r13), null, 27);      // 只换 rotation
if (r7.l() != null) {                        // PDF 背景页
    sw9 pdf = l7j.c(r7.l(), page.p(), page.F());
    r12' = m18.O(r12', pdf, null, null, 29);           // 换 sw9
}
m2d setter = qgh.b(r12');
ge8 op = u5j.s(x09, [new tz9(pageId)], null, setter, null, 10);
x82.I(m1d, [op], dof, iw3, this);            // 派发 ModifyPage
```

## 关键互证

- `cl4.java`：`a = new pce(new ra(29))`；`ra.java` default 返回
  `Float.valueOf(3.1415927f)` → V = π。轮换步长 V/2 = π/2，循环
  0 → π/2 → π → 3π/2 → 0；未命中任何基数比较（含 ≈3π/2 落到 else）→ 0。
- `ddg.g(nz9)`（ddg.java:146）：rotation 必须 ∈ {0, π/2, π, 3π/2}
  （1e-4 eps），否则 "Cannot rotate to non cardinal directions"。
- `m18.O(nz9, sw9, Float, qed, mask)`：null 参数保留原字段
  （`f==null → nz9.m()`，`sw9==null → nz9.l()`，`qed==null → nz9.n()`，
  margins `nz9.j()` 恒保留），mask 27/29 仅分别放行 rotation / sw9 替换。
- `l7j.c(sw9, i, i2)`（l7j.java:529）：重建 sw9 =
  `j7j.b(metadata, totalPageCount, 1, i2, [cropBoxes[i]], layout)` ——
  单页消费。`wz9`：`p() = this.m = pageInAsset - sw9.n()`（cropBoxes 下标），
  `F() = pageInAsset` 寄存器。即旋转时 PDF 页收敛为
  `pagesConsumed=1, pageOffset=pageInAsset, cropBoxes=[本页项]`。
- `u5j.s(x09, list, null, m2d, null, 10)` → `r0j.a(list, lxc, m2d, oz9)`：
  mask 10 置空 moveTo/书签，ge8 仅携带 field0 pages + field2 m2d。
- `m09`/`ddg.g` 校验链说明 nz9 合法性在 ModifyPage 解码侧强制执行。

## 结论

原版 Rotate Page 是**页级** `ModifyPage` 写（ge8.field2 → m2d → nz9），
不是笔记级 SET_METADATA；旋转步进 +π/2 模 2π（非基数归 0）；PDF 页附带
sw9 单页消费重建。渲染侧 nz9.m() 经 `wz9.j`（90°/270° 交换宽高）生效，
元素不做几何变换。
