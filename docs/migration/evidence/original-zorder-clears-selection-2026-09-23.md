# 原版证据：z-order 菜单动作无条件清空选区（xsc.q → this.K.a()）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 601 依据（修正 Phase 600 的 SEND_* 映射）。

## 1. `xsc.q` — 全部 z-order 动作的公共入口

```java
public final void q(ktc ktcVar, ix4 ix4Var) {
    xj2.A(h(), null, null, new zh9(this, ktcVar, ix4Var, null, 25), 3);
    this.K.a();                    // fvb.a() — 无条件清选区
}
```

`this.K` = `fvb`（`dhb` 中 `fvb fvbVar = xscVar.K` 证实）。

## 2. `dhb` 调用点

```java
case 6:  xscVar.q(ktcVar, new py(z9 ? 1 : 0, 26));   // SEND_FORWARD
case 7:  xscVar.q(ktcVar, new py(z5 ? 1 : 0, 26));   // SEND_BACKWARD
case 8:  xscVar.q(ktcVar, new cfc(9));               // SEND_TO_FRONT
case 9:  xscVar.q(ktcVar, new cfc(8));               // SEND_TO_BACK
```

四 case 都无独立 `fvbVar.a()`——清空发生在 `q()` 内部、
`zh9` 协程启动**之后无条件**执行：即使协程内部 no-op
（已置顶/无元素），选区同样被清。

## 3. 与其他动作的统一终态

合并 Phase 600 映射后，原版"动作后保留选区"的仅剩：
STYLE(nsc 弹层)、EDIT_MATH、CROP(itc.c)、DESELECT(模式)、
MORE(折叠)、CONVERT_*(转换流)。其余一切 mutating 动作
（COPY/CUT/DUPLICATE/GROUP/UNGROUP/DELETE/FLIP/LOCK/
SEND_*×4）成功后均无选区。

## 4. Harmony 侧

`reorderSelected`/`reorderSelectedToExtreme` 原保留选区（含
no-op early-return）。按 `q()` 的无条件语义，清空挂在
`onSelectionMenuAction` 分发层——菜单点选即清，与协程结果无关。
