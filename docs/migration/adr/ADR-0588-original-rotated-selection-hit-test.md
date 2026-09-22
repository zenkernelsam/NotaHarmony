# ADR-0588 — 旋转选区命中测试（yxi.e）

- 状态：Accepted
- Phase 619；对齐 `yxi.e` + `y18.c` + `htc.a()/g()` + `dl1` 调用点
  （decompiled_1.0.3）。

## 背景

原版把选区矩形存为「未旋转矩形 `htc.a()` + 旋转角 `htc.g()`」。
`yxi.e` 的命中测试：`g()==null` → 轴对齐包含；否则把测试点绕
矩形中心反旋转 `-g()`（`y18.c` 施加 `b(-f, center)` 矩阵）再做
轴对齐包含——即判定的是真实旋转四边形，而非旋转后的 AABB。

Harmony 旧实现：`selectionRect` 是已旋转元素的屏幕 AABB（比真实
四边形大），所有「点在选区内」判定用 `pointInRect`——AABB 四角区
误命中，按下点应判「外部」（取消选择/穿透命中下层）却进入
拖拽/缩放路径。

## 决策

1. 新增 `singleSelectedUnrotatedScreenRect()`：单个带
   `rotationRadians≠0` 的选中元素（`itc` 等价）→ 克隆元素置
   `rotationRadians=0` 取未旋转 `bounds` → `canvasToScreen` 得
   未旋转屏幕矩形 + 旋转角（`UnrotatedSelectionRect`）。
   - 形状分支收窄到 `ElementType.ELLIPSE`（`ShapeElement` 联合中
     唯一携带 `rotationRadians` 的成员；线/多边形的旋转已烘进顶点）。
   - 组选区/多元素选区/单笔 → null。
2. 新增 `pointInSelectionRect(touch)`：单旋转元素 → 触点绕未旋转
   矩形中心旋转 `-θ` 后对该矩形做 `pointInRect`（`y18.c`+`cmb.a`
   等价）；其余 → `pointInRect(touch, selectionRect)`（`g()==null`
   分支等价）。
3. 4 个「点在选区内」检查点（按下分发两处 + deselectMode 两处）
   全部切换到 `pointInSelectionRect`。

## 边界

- 多元素选区（`ftc`）的 `d` 旋转寄存器仅在「选区整体旋转」语境
  非零；Harmony 多元素各自持有 `rotationRadians`、无选区级旋转
  寄存器，退回 AABB——原版等效场景不可静态表达。
- 组选区（`gtc`）成员各自旋转：成员 `rotationRadians` 烘进各自
  `bounds`，选区壳无旋转 → AABB 等价。
- `lg2.f` 的 `htc` 分支（区域矩形↔内容中心偏移）经核查在
  Harmony 模型中无对应概念（`selectionRect` 即内容 AABB），无
  行为差，不移植。

## 证据

- `docs/migration/evidence/original-rotated-selection-hit-test-2026-09-28.md`
- `docs/migration/replays/d02-original-rotated-selection-hit-test.mjs`
  （17/17）
- `yxi.java:88-91`；`y18.java:76-95`；`dl1.java:114,182,212,267`
