# 原版证据：交互标记后 200ms 长按菜单抑制（yqa/g39.b()）— Phase 620

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。

## g39.java:17-31 — 标记与窗口判定

```java
public final void a() {
    this.d = Long.valueOf(System.currentTimeMillis());
    xj2.A(this.a, null, null, new u50(this, null, 20), 3);
}
public final boolean b() {
    Long l = this.d;
    return l != null && l.longValue() + 200 >= System.currentTimeMillis();
}
public final void c(cmb cmbVar, ktc ktcVar) {
    xj2.A(this.a, null, null, new e39(this, cmbVar, ktcVar, null, 0), 3);
}
```

- `a()` = 打点（`d` = 当前毫秒 + `u50` 协程）。
- `b()` = 「距上次打点 < 200ms」。
- `c()` = 经 `e39`/`v39` 向 `l51` 事件总线发射选区拖拽事件。

## g1f.java — 打点来源（k2f 手势回调分派）

```text
case1 (oda 长按)      → tf9 协程（菜单本体）
case2 (pca 链接)      → ns 协程（OPEN/COPY_LINK 菜单）
case4 (ktc 选区事件)  → if (ktc==null || !ktc.i()) Q.a()   ← 选区变空打点
case5 (pda/oda)       → uke.d 菜单关闭
default (r5f 手势面)  → N.a()+f0.a()+Q.a()                  ← 面切换打点
```

`k2fVar.Q` = `g39` 实例（与 `xsc.M` 同注入）。两类事件打点：
选区变空（`ktc==null || !i()`）与手势面切换（`r5f` 事件每次打点）。

## yqa.java:215-223 — 门消费点（长按粘贴菜单）

```java
if (z) {
    xj2.A(y49Var, null, null, new f39(g39Var, a76VarE, arrayList, e49Var, null, 0), 3);
} else {
    if (g39Var.b()) {
        return;                        // ← 标记后 200ms 内静默吞掉
    }
    xj2.A(y49Var, null, null, new f39(g39Var, a76VarE, arrayList, e49Var, null, 1), 3);
}
```

`z=false` 分支（非触控笔直发的长按分发）在标记窗内直接 return——
选区刚被清空或工具刚切换后 200ms 内的长按不弹菜单。

## ej9.java:248-254 — 同一窗口的第二消费点

```java
case 19:  // wtc（整选区拖拽结束）
    if (!g39Var.b()) {
        xj2.A(g39Var.a, null, null, new e39(g39Var, cmbVar, ktcVar, null, 1), 3);
    }
```

拖拽结束通知在标记窗内同样被吞——标记窗的双语义：「交互上下文刚
被重置（清空/切换），尾随事件与菜单都不应再产生」。Harmony 无
`l51` 事件总线/`v39` 通知，该消费面不可表达，记入 ADR 边界。

## Harmony 差异（修复前）

`bindContextMenu(ClipboardPasteContextMenu, LongPress)` 无任何抑制：
清空选区或切换工具后立即长按，粘贴菜单照常弹出。

## Harmony 对齐（修复后）

- 标记：`clearSelectionWithRegisterReset`（选区清空总漏斗）+ 页面
  加载 deselect + 过小区域选区丢弃 deselect，共 3 处写
  `lastSelectionClearTime`；`EditorViewModel.applyActiveState` 在
  `currentTool` 真正变化时写 `toolChangedAt`（r5f 面切换等价）。
- 门：`recentInteractionGateActive()` = `max(两标记)` 距今 <200ms；
  `ClipboardPasteContextMenu` 门内不产出 `MenuItem`（ArkUI
  `bindContextMenu` 无 veto，空 Menu 不弹层）。
