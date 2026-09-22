# 原版混淆类定位闭环（审计 3.3 四项）— Harmony 证据文档

- 日期：2026-09-22
- Phase：575
- 结论：全部闭环 —— A-15/A-17 已对齐，A-19 为恒等调用（无需修复），
  A-07 公式已精确一致，R-32 原版无固定深度上限（Harmony 双预算为移植侧
  有意上界）

## 原版证据（decompiled_1.0.1 `defpackage`）

### 1. `fc0` 实现类定位 → `hc0`（SingleAttribute）

`fc0.java` 是五存取器接口（`a()~e()`，全 double）。实现类：

- `hc0.java:5-44` = `SingleAttribute`，`toString` 给出权威字段名：
  `strokeWidth=I, force=J, altitudeAngle=K, azimuthUnitVectorX=L,
  azimuthUnitVectorY=M`。
- 存取器映射：`a()`→K=**altitudeAngle**、`b()`→L=**azimuthUnitVectorX**、
  `c()`→M=**azimuthUnitVectorY**、`d()`→J=**force**、`e()`→I=**strokeWidth**。
- `gc0.java` = 双 `fc0` 按 `K` 线性插值的包装器（`ic0.J(ow5)` 产出的即
  此类插值属性）。
- 旁证 `ke2.java`（ControlPoint）：`f()`→d=force、`d()`→e=
  azimuthUnitVectorX、`e()`→f=azimuthUnitVectorY、`c()`→g=
  altitudeAngle、`g()/h()`→pointX/pointY。ke2 不 implements fc0，
  编号体系不同（审计已警告不可互套）。

**A-15 闭环**：原版 `xaa.b` 中 `dA = fc0VarJ2.a()` 同时喂 angleDiff
（`π/5 − dA`）与尺寸因子第二参（`d(fc0.d(), dA)*0.5+0.5`）。`a()` =
altitudeAngle。Harmony `PencilSplatGenerator` 两处均已用
`attrs.altitudeAngleRadians`（`angleDiff` `:246` 与 `sizeFactorOf`
`:230-233`）——同源同字段，**已对齐，无需改动**。

**A-17 闭环**：`fc0.b()/c()` = azimuthUnitVectorX/Y——位置偏移方向取自
**笔杆方位角单位向量**，非曲线切向。Harmony `:263-266` 已用
`attrs.azimuthUnitX/Y` 并以 `(1,0)` 为缺失回退（对应原版 `a61.f()`
缺能力回退）——**已对齐**。

### 2. `f92.c(...)` → 仿射映射，非钳制

`f92.java:71-73`：`c(d, d2, d3, d4) = (d * d2 + d3) / d4`。
`xaa.b` 调用点 `f92.c(dSqrt2, 1.0, 0.0, 1.0)` = `(x·1+0)/1 = x`——
**恒等 no-op**。

**A-19 闭环**：所谓「opacity 最终钳制」根本不存在；该调用是恒等仿射。
Harmony `opacityFactor * edgeFactor * scaleBase`（`:283-284`）无缺失。

### 3. `dd4.d()` → clamp(·, 2.6, 18.0)，公式无 log

`dd4.java:46-60`：`d(d)` = `min(18.0, max(d, 2.6))`（含 NaN 守卫）。

`sqh.f` 容差第二参调用点（`ms1.java:180`）：

```java
d3 = (0.5 / ((((dd4.d(vy5Var.b() * vy5Var.a) - 2.6) / 15.4) * 1.5) + 1.0))
     / vy5Var.a;
```

- `vy5Var.b()` = 笔刷宽（`uy5.a()`，`vy5.java:53-55`）；
- `vy5Var.a` = 视口缩放（`ks1.java:284`：`ms1Var.e.a = hvfVar.a`）。
- 常数：clamp 区间 [2.6, 18.0]、归一化除数 15.4、斜率 1.5、基准 0.5。
- **无 Math.log**——审计猜测的对数项不存在，公式是有理式。

**A-07 闭环**：Harmony `computeOriginalFitTolerance`
（`CubicFitter.ets:28-32`）与该式逐项一致（clamp 上下界、15.4、1.5、
0.5、除以 zoom）。

### 4. 原版 undo 栈深度 → 无数值上限

- 文本编辑撤销：`nnf`（`nnf.java:19-24`）持两个 `ekd` 列表（undo/redo）；
  `ekd` 是 Compose 快照态持久 List（`isd`/`mjd`/`tjd`），**无容量界**。
- 会话撤销：`m1d.X0` → `n1d.X0` → `tzc`/`nzc` 协程走 CRDT op 态回放；
  `nzc.invokeSuspend` 未反编译，但 `tzc` 字段（`P/Q` 为 `bs1` 站点时钟、
  `R` LinkedHashMap、`a0` = 2 秒合并窗）中**无数值深度常量**——撤销深度
  由会话保留的 op 历史隐式界定。
- `p1d`/`o1d`/`x0d` 为 terminal/read-only 会话桩，仅记日志。

**R-32 闭环**：原版无「50 步」式计数上限；Harmony 现行
`UndoRedoManager` 双预算（`DEFAULT_HISTORY_MAX_ACTIONS=128` +
`maxEstimatedBytes=32MB`，`:585-586,882-885`）是移植侧内存安全上界，
作为有意发散记录，不再挂 ❓。

## Harmony 变更

无源码变更——四项均为证据闭环；数值与字段早已对齐或已按移植约束
有界化。仅新增 replay 钉住当前契约，防回归。

## 验证

- `d02-original-attribute-accessor-resolution.mjs`：钉住
  `computeOriginalFitTolerance` 常数、`angleDiff`/`sizeFactorOf` 同源
  altitudeAngle、散布方向用 azimuthUnitX/Y（含 (1,0) 回退）、undo 双预算。
- 全量 replay 与双 HAP 构建见 Phase 575 报告。
