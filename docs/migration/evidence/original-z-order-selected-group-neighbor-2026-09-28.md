# Evidence — z-order 一步移动中选中组不阻挡交换（zh9/py case26）

- 日期：2026-09-28；Phase 625
- 来源：`decompiled_1.0.3/sources/defpackage/{dhb,xsc,zh9,py,cfc,rsc,ssc,cqc}.java`

## dhb.java case6-9（z-order 菜单项分发）

```java
case 6:                       // SEND_FORWARD
    xscVar.q(dsc.F, dscVar2, ne9Var, linkedHashSet, ufbVar2, c0562, vx4Var);
case 7:                       // SEND_BACKWARD
    xscVar.q(dsc.G, ...);
case 8:                       // SEND_TO_FRONT
    xscVar.q(dsc.H, ...);
case 9:                       // SEND_TO_BACK
    xscVar.q(dsc.I, ...);
```

- case6/7 产 `new py(..., 26)`；case8/9 产 `new cfc(..., 8/9)`。
- 分发入口 `xsc.q` 对每个操作先建 z-order 准备协程 `zh9`。

## zh9.java p()（z-order 操作准备，zh9.java:276-354）

```java
if (ktcVar instanceof gtc) {
    iterableP = ys2.P(((gtc) ktcVar).a);            // :291 选中组的 cqc 成员集
} else if (ktcVar instanceof ftc) {
    Set set = ((ftc) ktcVar).m;                     // :293 ftc 成员集
    ...
}
LinkedHashSet linkedHashSetJ = ys2.J(ktcVar.f(), iterableP);   // :307
Set setH = ktcVar.h();                                        // :308 成员元素 id 集
...
// 页面 z 列表逐元素建 ssc 条目（:332-343）
und undVar = vndVar.O;                             // 元素的组成员关系
if (undVar == null || (id = undVar.a) == null) {
    id = vndVar.I.getId();                         // 非组成员 → 元素 id
}
qo5 qo5Var = new qo5(id);                          // :333-334 条目键=组 id 或元素 id
...
arrayList2.add(new ssc(qo5Var,
    undVar2 != null ? undVar2.b : vndVar2.I.g(),   // :343 组条目 z=组内最大 z
    undVar2 != null));                             //      c=true ↔ 组条目
...
if (!sscVar.c && ktcVar.f().contains(sscVar.a)) {  // :350 仅未组化已选元素
    arrayList3.add(sscVar);                        //      进 rscVar.b（可动集）
}
rscVar = new rsc(listK1, arrayList3, linkedHashSetJ); // :354
```

- **组在 z 列表里坍缩成一条以组 id 为键的条目**（`undVar.a`），
  `ssc.c=true`；未组化元素以元素 id 为键，`c=false`。
- `rsc.b`（`arrayList3`）= 移动者集：只收 `!c && f().contains(id)`
  的条目——**组条目与组成员永不进入可动集**。
- `rsc.c`（`linkedHashSetJ`）= 已选元素 id 集（`f()` ∩ 成员扩展）
  ——全部由**元素 id** 构成，不含任何组 id。

## py.java case26（向前/向后一步）

```java
LinkedHashSet linkedHashSet2 = rscVar.c;             // 已选集（元素 id）
List<ssc> list2 = rscVar.a;                          // z 条目序
int i3 = z ? 1 : -1;                                 // forward/backward 步长
for (int i = 0; ...; i++) {
    ssc sscVar2 = list2.get(i);
    if (linkedHashSet2.contains(sscVar2.a) && !sscVar2.c) {   // 移动者门
        ssc next = (ssc) au1.g1(i2 + i3, list2);     // 相邻条目
        if (next != null && !linkedHashSet2.contains(next.a)) {
            // 相邻组条目：交换者取 z±1 越过它
            if (next.c) { 新 z = z ? next.b + 1 : (next.b == 0 ? 0 : next.b - 1); }
            else        { 与邻居元素直接互换 z; }
        }
    }
}
```

- 移动者门 `contains(a) && !c`：`a` 是元素 id 时命中已选集；
  组条目的 `a` 是组 id，`linkedHashSet2` 只含元素 id →
  **组条目永不移动**，与 `!c` 冗余但双重保险。
- 邻居门 `!linkedHashSet2.contains(next.a)`：相邻**组条目**的
  `a` 是组 id → `contains` 永不命中 → **选中组与普通未选组
  一样不阻挡交换**。相邻已选非组元素（`contains` 命中）才阻挡。
- 语义推论：已选元素与已选组相邻时，元素交换 z（越过组时
  取 `组z±1`），组保持原位——组不被 z-order 操作整体搬动。

## cfc.java case8/9（置于最前/最后）

```java
case 8:  // TO_BACK：可动条目顺序排最底段索引
case 9:  // TO_FRONT：可动条目顺序排最顶段索引
```

- 只对 `rsc.b`（未组化已选）分配极端段索引；组条目与未选
  元素留在原相对位次——Harmony `movePageElementRefsToExtreme`
  moving/staying 分离实现已等价（含选中组不移动）。

## rsc/ssc/cqc.java（记录载体）

- `rsc{a=z 条目序, b=可动未组化已选条目, c=已选元素 id 集}`。
- `ssc{a=id 键(组 id 或元素 id), b=z 值, c=组条目标记}`。
- `cqc{id, members, rect}`——`gtc.a` 供 zh9 展开选中组成员。

## Harmony 偏离与修正

- `movePageElementRefsOneStep`（PageElementOrder.ets）原以
  `!selectedUnits.has(units[index + 1].id)` 判邻居是否阻挡——
  把**选中组单元也算作阻挡者**：已选元素与已选组相邻时元素
  不再移动，与 `py case26` 的 `contains(组id)` 永不命中语义
  相违。
- 修正：阻挡判定收敛为 `selectedUnits.has(unit.id) &&
  !unit.group`——**只有已选非组单元阻挡交换**；组单元（含
  选中组）恒为未选邻居，元素按既有 `neighbor.zIndex±1` /
  直接互换路径越过之。
- `movePageElementRefsToExtreme`：moving=已选非组单元、
  staying=其余全部（含选中组）——与 `cfc` case8/9 等价，未改。
- 纯组选中：`resolveOriginalSelectionLayerUnits` 产出的可动集
  为空 → 静默无操作，与 `rsc.b` 空集等价。
