# Phase 1457 证据 — 原版 utf(PinchTransform) 双指选区变换会话

证据来源：`decompiled_1.4.2/sources/defpackage/`（只读原版材料）。

## 会话类 `utf`

`utf.java` — PinchTransform 会话，字段：

- `a`：会话/选区标识（`getId`）。
- `b`：`Map` 原位置图（会话建立时 `guf.i(msf)` 捕获的 originalPositions）。
- `c`/`d`/`f`：打包点（`fom` 双浮点），构造器全部初始化为第二指触点 `j`。
- `e`：transientOpId（会话内操作的瞬时操作标识）。
- `g`：scale，`1.0f` 起；`k(f)` 写入。
- `h`：rotation，`0.0f` 起；`j(f)` 写入。
- `i`：`initialSelectionState`（`msf`）——提交/取消恢复用。

构造签名：`utf(bpj id, Map map, long j, long j2, long j3, msf msf)`——
三个 `j` 均为第二指触点，即初始枢轴/起点。

## 建立门 `guf.y(long j)`

在 `r`/`s` 指针协程内第二指按下时调用，条件全部满足才产 utf：

1. `this.h == null`——无任何活动变换会话（xtf/vtf/wtf/ttf 均占 `h`）。
2. 当前 `msfVar`（选区态）存在且其选区属于活动 note/page
   （`zx7.r(id, activePageId)` 校验）。
3. `!(msfVar instanceof hsf)` 分支解析——进行中绘制型选区（hsf）
   无 `rtf` 界供给 → 不成立。
4. `!(isf && isf.h)`——isf 点除模式（deselectMode）下不进入。
5. `!w(msfVar)`——`w` = 全部成员 `cjm.h`（POSITION_LOCKED）才不成立，
   即全锁定选区排除。
6. `lsf` 支：`(!z || !lsf.c)` 中 `lsf.c` = showUncroppedImage 旗
   （`lsf.java` toString 字段名确认）——lsf 且显示未裁剪图时排除；
   `ksf` 支旋转取自 `ksf.g()`，`lsf` 支取成员几何旋转。
7. 第二指点 `s64(j)` 经选区旋转 `f` 反旋（`f5n.g`）后，
   须通过 `rtfVar2.b().a(point)` 旋转系内界测试。
8. 通过则 `mapI = i(msfVar)` 捕获原位置，
   `this.h = new utf(id, mapI, j, j, j, msfVar)`。

## 更新 `guf.v(long j, float f, float f2, …)`

```java
utfVar2.a(j);              // 枢轴/当前点更新（f 字段）
utfVar2.k(f3);             // f = 双指距离比 → 等比缩放
fD = twm.d(f2, m);         // f2 = 连线角增量 → 90°/5° 吸附
utfVar2.j(fD);
```

随后 `scale≠1 ∨ rot≠0 ∨ transientOp` 时：

```java
r9a r9aVarM = m(utfVar2.h(), f3, fD, utfVar2.i(), false);
x(utfVar2, r9aVarM, …)     // 预览经会话操作管线
```

完成支（抬指）：

```java
this.a.c(bpjVarB, false, null, f6 /*scale*/,
  !(f7 == 0.0f) ? f7 : null /*rot 非零才传*/,
  new s64(utfVar.i()) /*pivot*/);
```

选区保留（不消除 msf）。

## 应用 `guf.m(Map map, float f, float f2, long pivot, boolean z)`

逐成员：`pos' = pivot + f·(pos − page − pivot)`，再绕 pivot 旋转 `f2`
（`f5n.g(jF, f5n.c(pivot, f2))`），复合即 `T(p)·R(θ)·S(s)·T(−p)·base`；
`z` 为页框钳制开关（预览 false / 提交 true）。
`twm.d(f, m)`：`|f − k·90°| < m` 时贴齐，阈值 `m = fq9.z(5f) = 5°`，
吸附集 `guf.n = {-π, -π/2, 0, π/2, π}`（si5.a=π 基准）。

## Harmony 现状（移植前）

`NoteCanvasView.ets` 多点分支一律 `cancelActiveInteraction()`；
声明式 `PinchGesture`/`PanGesture({fingers:2})` 只做视口 zoom/pan——
无选区内容变换会话，utf 语义整体缺失。
