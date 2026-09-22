# Phase 624 — 区域选择 inside 判定改用绘制矩形（ftc.a / yxi.e）

## 原版证据

- `uw2.java` case1（97-108）：区域选择完成 →
  `new ftc(cmbVar, cmbVar, cmbVar, …)`——`cmbVar` 为绘制区域
  bounds，三个矩形字段全取它，不按命中元素重算。
- `ftc.java:83`：`a()` 返回 `this.a`（绘制矩形）；`ftc.e`（:98）
  变换提交把 `qpi.b(this.b, transform)` 写回 `a`/`b`——绘制
  矩形随选区变换演化。
- `dl1.java:114/212`：`yxi.e(ftcVar.a, jE, ftcVar.d, fi3.b(a))`
  ——inside 判定测绘制矩形（绕其中心反旋转），不是成员 union。
- `ftc.o`（成员 union，`qpi.c`）仅用于覆盖层显示——判定矩形
  与显示矩形原版就是两个字段。

## 排查结论

Harmony `pointInSelectionRect` 对所有多元素选区用成员 union：
绘制区覆盖成员空隙时，空隙内按下误判 outside → 走外侧探针
取消选区；原版判 inside → `wtc` 拖拽。单元素 marquee 也错误
地走元素命中（原版产 `ftc` 仍测绘制矩形）。

## 修复

- `SelectionState.drawnRect`（画布坐标）：`finalizeSelection` 提交
  时存 `drawnBounds()` 克隆；`selectElementIds`/`deselect`/
  `beginSelection` 置 null（点选/全选/粘贴无绘制矩形）。
- `drawnRectTransformed()`：`drawnRect` 按 `state.transform` 做
  4 角变换外接矩形——等价 `ftc.e` 的 `a = qpi.b(b, transform)`。
- `pointInSelectionRect`：`drawnRect!=null` → 屏幕投影 +
  `uniformSelectionCarrierRadians()` 反旋转 `-θ`（绕绘制矩形
  中心）的 yxi.e 等价包含测试，置于单元素元素命中之前；
  `drawnRect==null` → 原 itc/union 路径不变。
- 覆盖层 `selectionRect` 保持成员 union（`ftc.o` 等价）。

## 验证

- 新增 replay `d02-original-drawn-rect-inside-check.mjs`：20/20 绿。
- itc-element-hit-dispatch / rotated-selection-hit-test fixture
  窗口加宽后 17/17、18/18 绿；tap-clear/deselect-mode/
  text-surface-dispatch 等关联 fixture 全绿。
- 全量 desktop replay 套件：514/514 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。
- 未启动模拟器/真机/Hypium。

## 已知边界

纯笔画旋转选区的 inside 判定按 θ=0 退化（笔画旋转烘进
path/bounds，无可携带成员反映壳 θ）——fail-closed 近似，
已登记 ADR-0593。
