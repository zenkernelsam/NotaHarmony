# Evidence — 区域选择 inside 判定用绘制矩形（ftc.a / yxi.e）

- 日期：2026-09-28；Phase 624
- 来源：`decompiled_1.0.3/sources/defpackage/{uw2,ftc,dl1,yxi,fi3,qpi}.java`

## uw2.java case1（矩形/套索完成提交，uw2.java:97-108）

```java
Set set = mqcVarC.a;                     // 命中实体 id 集（组扩展后）
Set set2 = mqcVarC.b;
if (ftcVar == null) { ... }              // 当前壳必须是 ftc（区域选择）
else if (set.isEmpty()) { fvbVar.a(); }  // 空命中 → 取消
else {
    ne9Var.d(new ftc(cmbVar, cmbVar, cmbVar, null, null, false,
        setX1, null, null, set2, set2, 896));
}
```

- `cmbVar` = `ftcVar.a`（进行中壳的绘制矩形，oo3 会话的
  drawnBounds）——新 ftc 的 **a/b/c 三个矩形字段全部 = 绘制
  矩形**，不是命中元素的 union。
- 命中集合只含 id 集（`setX1`/`set2`），矩形字段从不按成员
  重新计算——即使命中元素在绘制区内分布稀疏。

## ftc.java（壳字段语义）

```java
public final cmb a() { return this.a; }        // :83 — inside 判定矩形
public final cmb d() { return this.c; }        // :93 — 拖拽负载矩形
public final Float g() { return this.d; }      // :145 — 壳旋转寄存器
```

`ftc.e(z, dragDelta, scale, rotation, pivot)`（ftc.java:98）变换
提交：`ehfVarB = qpi.b(this.b, this.e, …)` 以 `this.b` 为基计算
变换，`z=true` 提交时 `j(this, cmbVar, cmbVar, cmbVarF, f3, f3,…)`
——`a`/`b` 写回变换后的绘制矩形，`c` 写旋转校正矩形，`d`/`e`
更新壳旋转。绘制矩形随选区变换演化，永不按成员 union 重算。

## dl1.java（inside 判定分派）

```java
// :103-120 — 先做 id 集限定的元素命中（同 id → stc/utc）
ptc ptcVarA3 = xtcVar.a(jE, set);
// :114, :212 — 再退化到绘制矩形的旋转包含测试
cmbVar = ftcVar.a;
yxi.e(cmbVar, jE, ftcVar.d, fi3.b(cmbVar))
```

`yxi.e`：触点绕 `fi3.b(a)`（绘制矩形中心）反旋转 `-d` 后对
`a` 做轴对齐包含测试；`d==null` 时退化为普通矩形测试。

## 语义结论

- 区域选择（套索/矩形）的 inside 判定 = **绘制时记录的矩形**
  （随变换演化），覆盖成员元素之间的空隙：空隙内按下 →
  inside → `wtc` 拖拽选区。
- 只命中一个元素的区域选择也产 `ftc`（无 `itc` 退化），同样
  走绘制矩形判定。
- 点选（`uw2` case3 `otc`/`ntc`）、全选、粘贴产生的选区没有
  绘制矩形——`itc` 走元素命中、`gtc` 用组存储矩形 `cqc.c`。
- 覆盖层显示 bounds 用 `ftc.o`（成员 union，`qpi.c` 旋转并集）
  ——**显示矩形与判定矩形原版就是两个不同字段**。

## Harmony 对齐前差距

`pointInSelectionRect` 对所有多元素选区用成员 union
（`selectionRect` / 未旋转并集）：绘制区大于 union 时，空隙内
按下 → 判 outside → 走外侧探针取消选区，与原版 wtc 拖拽
不一致；单元素 marquee 也走元素命中而非绘制矩形。

## Harmony 对齐后

- `SelectionState.drawnRect`：`finalizeSelection` 提交时存绘制
  bounds（`drawnBounds()` 克隆，画布坐标；套索=路径 bounds，
  矩形=绘制 rect）。
- `drawnRectTransformed()`：`drawnRect` 按 `state.transform`
  （累积壳变换）做 `transformBounds`（4 角变换外接矩形）——
  等价 `ftc.e` 把 `qpi.b(b,transform)` 写回 `a`。
- `pointInSelectionRect`：`drawnRect!=null` → 投影屏幕 +
  `uniformSelectionCarrierRadians()` 反旋转测试（yxi.e 等价）；
  在单元素元素命中之前（marquee-of-1 仍是 ftc）。`drawnRect
  ==null`（点选/全选/粘贴/itc/gtc）→ 原路径不变。
- 覆盖层 `selectionRect` 仍用成员 union（`ftc.o` 等价），不变。

## 验证

- 新增 replay `d02-original-drawn-rect-inside-check.mjs`：20/20 绿。
- itc-element-hit-dispatch / rotated-selection-hit-test fixture
  窗口随函数增长加宽后 17/17、18/18 绿。
- 全量 desktop replay 套件 514/514 绿。
- `note@default` / `note@ohosTest` HAP 构建绿。
