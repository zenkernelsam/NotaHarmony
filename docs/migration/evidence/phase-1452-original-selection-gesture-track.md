# Phase 1452 证据 — 原版选区手势轨迹：hsf.a 为 lasso/rect 共用指针轨迹

## 原版证据（decompiled_1.4.2/sources/defpackage）

### hsf —— 进行中选区手势状态（hsf.java）

```java
public final class hsf implements msf {
    public final List a;   // 指针轨迹点列
    public final sbe b;    // 累积 bounds（RectF 同构）
    public final bpj c;    // 内容令牌
}
```

`hsf` 不区分套索/矩形——**两模式共用同一追踪器**。

### lr case13 —— 手势更新变换（lr.java:95-101）

```java
hsf hsfVar = msfVar instanceof hsf ? (hsf) msfVar : null;
ArrayList arrayListO3 = e52.O3(hsfVar.a, new s64(j));   // a' = a + 新点
sbe sbeVar = hsfVar.b;
return new hsf(arrayListO3, new sbe(                    // b' = 扩展 bounds
    Math.min(sbeVar.a, s64.e(j)), Math.min(sbeVar.b, s64.f(j)),
    Math.max(sbeVar.c, s64.e(j)), Math.max(sbeVar.d, s64.f(j))), hsfVar.c);
```

即：每次 touchMove，**轨迹逐点追加**到 `hsf.a`，同时 `hsf.b` 按 min/max 累积。矩形模式没有任何"只存矩形"的分支。

### sen:1051 → gsf.d —— 进行中渲染

```java
// sen.java 分发：isf → sen.t；hsf → gsf.d(j(), zoom, open, f12)
```

`gsf.d` 对 `hsf.a` 逐点连成 path 描边：4dp/zoom 宽、9dp/zoom 虚线、`f12` 相位
行进（蚂蚁线），色 `#FF4278FF`。**矩形模式进行中画的是指针拖行轨迹
（斜线/曲线），不是矩形轮廓**。

### z6c case6 —— 完成时转入 isf（z6c.java:140-154）

```java
hsf hsfVar = msfVar instanceof hsf ? (hsf) msfVar : null;
if (hsfVar == null || !hsfVar.c.equals(bpjVar)) return msfVar;
if (set.isEmpty()) return null;            // 空命中 → 丢弃
sbe sbeVar = hsfVar.b;
List list = hsfVar.a;
return new isf(sbeVar, sbeVar, sbeVar, null, null, false,
               set, list, list, set2, set2, 896);
//              ↑k    ↑l = hsf.a 指针轨迹（两模式相同）
```

**`isf.k = isf.l = hsf.a`**——矩形模式绘制完成的选区，其 ghost 轨迹同为
指针原始轨迹；`isf.a/b/c = hsf.b` 累积 bounds。

## Harmony 纠偏

| 原版 | Harmony（修复后） |
|------|-------------------|
| `hsf.a` 指针轨迹（两模式） | `SelectionState.lassoPoints` 两模式逐点记录 |
| `hsf.b` 累积 bounds | `SelectionState.rect`（rect 模式） |
| `gsf.d(hsf.a)` 进行中 | `renderSelectionGestureTrail` 恒画 lassoPoints |
| `isf.k/l = hsf.a` ghost | `renderSelectionTrailGhost` 不限 lasso |
| rect 命中语义 | `rect` 界判定不变（drawnBounds/selectionPath 模式门保持） |

## 修改点

- `SelectionTool.updateSelection`：lassoPoints 恒追加（=hsf.a），rect 模式
  继续维护 `rect` 界（=hsf.b）。
- `NoteCanvasView.renderSelectionGestureTrail`：删除矩形轮廓分支，两模式
  统一描边 `lassoPoints`。
- `NoteCanvasView.renderSelectionTrailGhost`：去除 `mode===LASSO` 门——
  矩形绘制选区的 ghost 同样呈现指针轨迹。
