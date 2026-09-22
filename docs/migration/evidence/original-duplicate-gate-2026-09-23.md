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

## 纠正（case 序即 dsc ordinal）

初版将 case4 判为 DUPLICATE 有误。复查 dsc.java:31-43：
STYLE=0, COPY=1, CUT=2, **DUPLICATE=3**, **GROUP=4**, UNGROUP=5——
dhb 的 switch 就是 dsc.ordinal()，故：

- case4（上文代码段）= **GROUP** 建组：ftc 限定 + A1>=2 +
  kk9(29,...) 协程 + fvb.a() 清选区。
- case3 = **DUPLICATE**：xj2.A(..., new vsc(xscVar, ktcVar, cg2Var,
  z7 ? 1 : 0), 3)。vsc.java:45-80——I==1 → lg2.b。
- lg2.java:171-191：b() = g() 构建负载 → fvb.a() 清选区 →
  e() 就地应用负载（粘贴即重选），对任意 ktc 生效——
  itc 单元素、gtc 单组均可 DUPLICATE，**无数量门槛**。

A1>=2 门槛属 GROUP。Harmony 的 selectionCanGroup =
resolveOriginalGroupAuthoringMembers(...) >= 2 本就已等价
（authoringMembers = T1(ftc.q)+组id 等价集）。

## Harmony 状态（纠正后）

DUPLICATE 菜单无条件 push、duplicateSelected 无门槛——与
lg2.b 对任意 ktc 生效一致；pasteClipboard 粘贴后
selectElementIds 重选，对应 fvb.a() + e() 清选+重选。
初版误加的 selectionCanDuplicate/canDuplicate/执行端门槛
已全部撤销。
