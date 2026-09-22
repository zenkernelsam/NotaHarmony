# 原版证据：UNGROUP 仅 gtc 单组选区可触发（dhb case5）— Phase 616

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。

## dhb.java:17655-17672（菜单 case5 = UNGROUP，dsc=5）

```java
case 5:
    if (!(ktcVar instanceof gtc)) {
        if (ktcVar instanceof ftc) {
            cqc cqcVar = (cqc) au1.H1(((ftc) ktcVar).m);   // ftc.m 首组
            listN0 = m18.n0(cqcVar != null ? cqcVar.a : null);
        } else if (!(ktcVar instanceof itc) && !(ktcVar instanceof etc)) {
            o14.t();                                      // 不可达检查
            return null;
        }
        cg2Var = cg2VarB;
        return mof.a;          // ftc：算出 listN0 后直接返回——不派发 wsc
    }
    listN0 = m18.l0(((gtc) ktcVar).a);                     // 单组成员列表
    if (!listN0.isEmpty()) {
        xj2.A(xscVar.h(), null, null,
            new wsc(z8 ? 1 : 0, cg2Var, xscVar, listN0), 3);  // 解组协程
        fvbVar.a();                                         // 清选区
    }
    return mof.a;
```

- `gtc`（整个选区 = 单个组）→ `wsc` 解组协程（成员集非空时）+
  `fvb.a()` 清选区。
- `ftc`（多选壳，含「仅一个组 + 其他元素」的混选）→ 只解析了
  `ftc.m` 首组的成员集 `listN0`，随后 `return mof.a`——**不派发
  `wsc`，UNGROUP 对多选是死操作**。
- `itc`/`etc` → 落到 `o14.t()` 不可达分支，同样不执行。
- 结论：原版解组门槛 = 整个选区恰为单个组（顶层项 = [组id]），
  混选含单组在原版不可解组。

## 邻近 case 对照（case 序即 dsc ordinal）

- case2(CUT)/case3(DUPLICATE)：`vsc` 变体协程 → `lg2.d`/`lg2.b`。
- case4(GROUP)：`ftc` + `A1>=2` + `kk9` 建组 + `fvb.a()`。
- case10(DELETE)：`kk9` 变体28（`ktc.h()` 全成员集）+ `fvb.a()`。

## Harmony 差异与修复

旧实现：`selectionCanUngroup = selectedGroupIds.length === 1 &&
组存在 && 叶子可解析`——混选 {组+散件} 仍显示并执行解组。

Phase 616：门槛改为「顶层项恰为 [组id]」——
`groupMembers.length === 1 && groupMembers[0] === selectedGroupIds[0]`
（`resolveOriginalGroupAuthoringMembers` = `ftc.q` 散件 + 组 id
等价集）；`ungroupSelectedElements` 执行端同门槛 fail-closed。
单组选区行为不变（`l0(gtc.a)` 非空 ≡ 叶子可解析）。
