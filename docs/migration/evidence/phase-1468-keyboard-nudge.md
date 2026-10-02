# Phase 1468 — 方向键微移选区（f2 兜底链 → guf.g ntf/otf 通道）

## 原版证据（decompiled_1.4.2）

### 键位与步长常量

- `pa8.java:87-90`：`e/f/g/h = ofk.e(19..22)` = Android
  `KEYCODE_DPAD_UP/DOWN/LEFT/RIGHT`。
- `bd8.java:44-47`：`j0 = {e,f,g,h}`（方向键集）、`l0 = 2.0f`
  （微移步长，文档单位）。

### f2.java:285-325 — 兜底链分发

外层门：`!(Q.m instanceof rsi)`（非文本编辑会话）+ 键 ∈ j0 +
无修饰键（`db8.r/q/s` 即 ctrl/alt/shift 排除）。

- `lxm.a(o(keyEvent), 2)` = **DOWN**（`lxm.a=i==i2`）：
  - `d63Var.f.F == null || !u7bVar.g`（无活跃选区或键盘模式旗关）
    → **视口滚动**：`jP = mfc.p()`（视口尺寸），
    `jA = ndf.a(±i7, ±i8)`，其中 `i7/i8 = 视口宽/高 × f(=0.1f)`
    ——按方向滚动 10% 视口。
  - 否则 → `gufVar.g.p(new ntf(s64.a(±l0 轴向),
    repeatCount > 0))` = **选区微移步进 ±2.0 文档单位**。
- `lxm.a(iO, 1)` = **UP** → `gufVar.g.p(otf.a)`（NudgeEnd）。

### ms1.java:784 — 触摸面同推 NudgeEnd

触摸分发 lambda `a()` 在未消费路径尾部 `gufVar.g.p(otf.a)`——
任何触摸按下都终结挂起的微移会话。

### guf.t / guf.u — 步进与收尾

- `guf.t(j, z, qs2)`：`this.h==null && (!z || this.i!=null)` 门
  （**isRepeat 事件在没有在飞微移会话时忽略**）；`this.i` 惰性建
  `xtf(id, mapI, 0L, 0L, msf)`；`xtf.a(g()+j)` 累积位移；
  `p(map, jF, false)` 产平移 op → `x()` 事务化；`ome.c(id, false,
  s64(jF), null, null, null)` 更新选区偏移显示。
- `guf.u(z)`：NudgeEnd——`p(map, jF, true)`（z=true 走越页迁移
  `a()`）+ `x6n.c(t87)` 元素 op + `ksf.e(true, s64(jF))` 选区矩形
  平移 + `fq9.d0` 单事务提交；`a.g(ksf)` 通知。
- `guf.x:1260`：`qph instanceof r9a && r9a.k()==0` → 跳过整个
  ds3 事务——零位移微移不产生文档写/撤销步。

### u7b.g 键盘模式旗

`u7b.g = ec2.e0(组合流, …, TRUE)`——默认 true 的键盘光标/导航
模式旗（组合笔记级旗与内部 ptg 态）。默认态下微移直接可用。

## Harmony 缺口

`onCanvasKeyEvent` 覆盖缩放/剪贴板/工具快选/ESC，但 **方向键完全
未处理**——无选区微移、无视口滚动支。

## Harmony 对齐实现（NoteCanvasView.ets）

- `isSelectionNudgeKey`：Harmony DPAD 键码 2012..2015。
- `onSelectionNudgeKeyDown`：选区活跃 → 首步 `selectionNudgeActive`
  + 捕 `dragBefore*` 快照，`moveSelected(±2.0)` 步进 +
  `applySelectionTransform` 以快照基线重建；无选区 →
  `viewport.setScroll(±0.1×视口)`。
- `endSelectionNudgeCommit`：UP 或触摸到达（onTouchDown 顶部
  `ms1:784` 等价）触发——恒等跳过（r9a.k()==0 等价），否则单条
  TRANSFORM_ELEMENTS 撤销 + persist + 重选保留选区。
- `applySelectionTransform` 基线源扩展 `selectionDrag ||
  selectionNudgeActive`。

## 遗留差异

- `u7b.g` 键盘光标模式旗：Harmony 无键盘光标系统（pa8.G 建选区
  支未移植），按默认 true 等价处理——选区活跃即可微移；
  原版 u7b.g=false 时会回退滚动支，此降级路径未复刻。
- `isRepeat` 门在 Harmony 由长按重复 Down 天然落同一会话等价。
- 越页微移（guf.u z=true → a() 跨页迁移）维持 fail-closed
  （Harmony 逐页模型无跨页事务设施，登记同 P1459）。
