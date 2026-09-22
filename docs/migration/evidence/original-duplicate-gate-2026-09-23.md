# 原版证据：DUPLICATE 的顶层项 >=2 门槛（dhb case4）— Phase 615

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。

## dhb.java:17638-17654（菜单 case4 = DUPLICATE）

```java
case 4:
    ftc ftcVar = ktcVar instanceof ftc ? (ftc) ktcVar : null;
    if (ftcVar != null) {
        List listT1 = au1.T1(ftcVar.q);              // 未入组散件 id
        Set set2 = ftcVar.m;                          // 选中 cqc 组集
        ArrayList arrayList5 = ...cqc.a 收集组 id;
        ArrayList arrayListA1 = au1.A1(listT1, arrayList5);
        if (arrayListA1.size() >= 2) {
            xj2.A(xscVar.h(), null, null,
                new kk9(29, (ef2) cg2Var, xscVar, arrayListA1), 3);
            fvbVar.a();                               // 清选区
        }
    }
    return mof.a;
```

- `ktcVar` 非 `ftc`（`itc` 单元素、`gtc` 单组、`etc` 绘制中）→
  整个 case 静默返回：单选 DUPLICATE 是死操作。
- `ftc.q`：未入组散件 id 集（`gtc.f()` 返回 `qw3` 空集——
  `gtc.java:90-93`——组成员不进 `q`）。
- `ftc.m`：选中 `cqc` 组集，展开为组 id 追加。
- 门槛：`散件 id + 组 id >= 2`——即**顶层项 >=2**；
  一个含 3 成员的组只算 1 项，选不中第二项就不可复制。

## 邻近 case 对照

- case5（UNGROUP）：`gtc` → `l0(gtc.a)`；`ftc` → `ftc.m` 首个
  `cqc.a`；`wsc` 协程 + `fvb.a()`。
- case6/7：`xsc.q(ktc, new py(z, 26))` 样式预设应用。
- case8/9：`xsc.q(ktc, new cfc(9/8))`。
- case2/3：`vsc` 协程（copy/cut 变体，z4/z7 标志）。
- case20（dhb.java:18036 附近）：`fvb.n = ftcVar2` +
  `ftc.j(..., true, ..., 16255)` deselectMode 进入。

## Harmony 差异与修复

旧实现：`SelectionOverlay` 无条件 push DUPLICATE 菜单项，
`duplicateSelected` 无门槛——单元素/单组均可复制，原版不可。

Phase 615：`selectionCanDuplicate` =
`resolveOriginalGroupAuthoringMembers(...) !== null && .length >= 2`
——该函数即 `T1(ftc.q) + 组 id` 等价集（散件剔除组内成员后
+ 组 id），与 GROUP 门槛共用同一计算（5961-5964 已有）。
菜单项 `if (this.canDuplicate)` 条件 push；`duplicateSelected`
同门槛 fail-closed 兜底（对应 `ftcVar == null` 静默路径）。
CUT/COPY 无此门槛，不受影响。
