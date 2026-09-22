# 证据：原版胶带点按揭示（dl1 → xtc.b → ej9 → xo5，2026-09-28，Phase 586）

证据源：`decompiled_1.0.3/sources/defpackage/*.java`（1.0.3 反编译）。

## 1. 触发面：`dl1` case 2（pointer-down）

`dl1.java:80-95` —— 画布每次 pointer-down，先算画布坐标 `jE`，随后：

```java
ej9 ej9VarB = xtcVar.b(jE);
if (ej9VarB != null) {
    return ej9VarB;
}
```

`b(jE)` 的调用位于 `ktc` 工具状态机分发**之前**——命中 tape 时返回的
`ej9` 动作即本次手势的全部结果，工具分发不再执行（手势被消费）。

## 2. 命中与收集：`xtc.b`（xtc.java:39-73）

```java
// 伪码还原
otc hit = xtcVar.a(jE);                 // 命中测试：点下最上层元素
if (hit == null || !hit.a().I.k()) {    // I.k() = 该元素是否 tape
    return null;
}
List covering = fu1.f(...);             // 区域查询：覆盖该点的全部元素
Set ids = covering.filter(e -> e.I.k()).map(id).toSet();
if (ids.isEmpty()) {
    ids.add(hit element id);            // 兜底：首个命中 tape 的 ID
}
return new ej9(20, this, ids);
```

要点：

- 首层判定是"点下的元素必须是 tape"（tape 永远渲染在最上，见
  `vnd.compareTo`，Phase 582 —— 故"有 tape 覆盖该点"⟺"命中元素是
  tape"）。
- `fu1.f` 收集**覆盖该点的所有** tape 元素 ID，而非只取顶层一个。
- 区域查询为空时回退首个命中 ID。

## 3. 派发：`ej9` case 20（ej9.java:256-263）

```java
fvbVar2.a.c(new xo5(i2, set6));   // i2 = 2
```

`xo5` case 2 = 对"已揭示 tape ID 集合"（`NoteSessionState.revealedTape`，
`yd9.j`，会话级）做集合 toggle。

## 4. Toggle 语义：`xo5` case 2（xo5.java:32-50）

```java
if (revealedSet.containsAll(incoming)) {
    revealedSet.removeAll(incoming);   // 全部已揭示 → 整组隐藏
} else {
    revealedSet.addAll(incoming);      // 否则 → 整组并入（揭示）
}
```

与全局 Hide/Reveal Tapes（`oh9` → `np0` case5，Phase 583）同一套
toggle 语义，只是作用集合 = 该点覆盖的 tape 集合。

## 5. Harmony 对齐（Phase 586）

| 原版 | Harmony |
| --- | --- |
| `dl1` case2：`xtc.b(jE)` 先于工具状态机 | `NoteCanvasView.onTouchDown`：`tapRevealTapeAt(canvasP)` 先于橡皮/选区/激光/书写分发（选区菜单屏幕坐标守卫之后）；DEFAULT 文本模式分支内同样先行探测——`dl1` 对所有工具无差别拦截 |
| `xtc.a` 命中测试 + `I.k()` tape 判定 | `tapeIdsAtPoint`：笔画 `renderSpec.tapePattern != null` 且 `EraserEngine.hitStrokeAtPoint`（中心线 ± brushWidth·widthFactor·scale/2，复用橡皮采样管线的 transform/三次曲线语义）；形状 `originalTool === 3` 且 `tapeHitTestShape`（与橡皮同一覆盖几何：中心线带宽 + 闭合填充内部，但不受 `positionLocked` 约束——揭示不是编辑） |
| `fu1.f` 收集覆盖该点的全部 tape ID | `tapeIdsAtPoint` 返回全部命中 ID（命中即收集，非只取顶层） |
| `ej9` case20 → `xo5` case2 集合 toggle | `tapRevealTapeAt`：`every(revealed)` → 整组 `delete`，否则整组 `add`；`emitTapeRevealState()` + `renderFrame(true)` |
| `b(jE)` 非空即消费手势 | 命中返回 true → `onTouchDown` 早退，`isDrawing` 保持 false（move/up 均为 no-op）；DEFAULT 分支内同时复位 `lastTapTime` |
| `pageTapeIds`（Phase 583 全局开关集合） | 同步扩展为含 `originalTool === 3` 形状——与 `vnd` 排序、本点按收集的元素域一致 |

## 6. Replay

`docs/migration/replays/d02-original-tape-tap-reveal.mjs`（23 项断言）。
