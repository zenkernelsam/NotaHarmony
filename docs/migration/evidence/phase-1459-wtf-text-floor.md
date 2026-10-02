# Phase 1459 证据 — 原版 wtf 文本块 16px 缩放下限

证据来源：`decompiled_1.4.2/sources/defpackage/guf.java`。

## `guf.h(Map, f, f2, j, z)` — wtf 逐成员应用（guf.java:280-354）

```java
pfg pfgVarA = null;                       // jv6 文本成员才有值
if (jv6Var != null) { pfgVarA = jv6Var.a(); }   // 文本框尺寸 (d=宽, c=高)
float fD = hv6Var.b().d();               // 成员现有缩放 X
float fC = hv6Var.b().c();               // 成员现有缩放 Y
float fD2 = pfgA.d()>0 ? 16/(pfgA.d()*fD) : 0; // X 轴下限因子
float fC2 = pfgA.c()>0 ? 16/(pfgA.c()*fC) : 0; // Y 轴下限因子
if (f  >= fD2) fD2 = f;                  // fD2 = max(请求 sx, 下限)
if (f2 >= fC2) fC2 = f2;                 // fC2 = max(请求 sy, 下限)
float f3 = fD * fD2;                     // 最终缩放 = 现有 × 钳制因子
float f4 = fC * fC2;
```

语义：文本块自由缩放时，逐轴保证 `框宽/高 × 现有缩放 × 因子 ≥ 16`
（不压到 16 显示单位以下）。非文本成员（pfgVarA==null）下限为 0
即不钳制。

## 对照：`guf.m`（utf 捏合）无此下限

`m()` 直接 `fD = hv6Var.b().d() * f` —— 无 pfg/jv6 支，等比缩放
不钳制文本。故下限仅属 wtf 双轴缩放路径。

## `z`（页框迁移）支——本 Phase 登记为 fail-closed

`guf.a(jwf, e8d)`：成员 `e8d.d()∉[0,pageH]` 时经 `zq.n0(r0b, fD)`
找绝对 Y 命中的目标页，返回新 `cbc`（页引用）+ 重算相对坐标的
`e8d` —— 即**变换提交时跨页迁移成员**。Harmony 编辑器为逐页
模型（`switchPageData` 单页装载、撤销记录页内 before/after），
跨页迁移 + 跨页撤销无对应设施——登记 fail-closed 差异，
不在本 Phase 强行实现。

## Harmony 移植

`applySelectionResize` 的 `resizeFreeScale`（lsf+单文本块）分支：
以 `dragBeforeTextBlocks` 会话前快照取 `blockWidth/blockHeight` 与
`transform` 轴幅（`hypot(m0,m3)`/`hypot(m1,m4)`），逐轴
`scale ≥ 16/(dim·existing)` 钳制。
