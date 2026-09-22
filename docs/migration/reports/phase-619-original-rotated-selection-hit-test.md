# Phase 619 — 旋转选区命中测试（yxi.e）

## 原版证据

- `yxi.java:88-91` `e(cmb, j, f, j2)`：`f==null` → `cmb.a(j)`
  轴对齐包含；否则 `cmb.a(y18.c(j, b(-f, j2)))`——测试点绕中心
  反旋转 `-f` 后做矩形包含。
- `y18.java:76-95`：`c(j, fArr)` 4×4 仿射点变换；`b(-f, j2)`
  构造绕 `j2` 旋转 `-f` 的矩阵。
- `htc.java`：`a()`=未旋转选区矩形；`g()`=选区旋转角（Float，
  无旋转时 null）。
- `dl1.java:114,182,212,267`：`itc`/`ftc` 全部「点在选区内」
  判定经 `yxi.e(rect, point, g(), rectCenter)`。
- 入口线索 `lg2.f`：`htc` 分支的区域矩形↔内容中心偏移在
  Harmony 模型中不可表达（`selectionRect` 即内容 AABB），核查
  后确认无行为差；同一接口的 `g()` 旋转寄存器对应本 Phase。

## 排查结论

Harmony `selectionRect` = 已旋转元素的屏幕 AABB（比真实旋转
四边形大）；4 个「点在选区内」判定用裸 `pointInRect`，AABB
四角区误命中——应判「外部」的按下点进入拖拽/缩放/deselectMode
路径。

## 修复

- `singleSelectedUnrotatedScreenRect()`：单个带
  `rotationRadians≠0` 的选中元素（`itc` 等价）→ 克隆去旋转取
  未旋转 `bounds`→`canvasToScreen` 屏幕矩形 + 旋转角
  （`UnrotatedSelectionRect`）。形状分支收窄 `ELLIPSE`
  （联合中唯一旋转寄存器携带者）；组/多元素/单笔 → null。
- `pointInSelectionRect(touch)`：单旋转元素 → 触点绕未旋转
  矩形中心旋转 `-θ` 后 `pointInRect`（`y18.c`+`cmb.a` 等价）；
  其余 → 原 AABB（`g()==null` 分支等价）。
- 4 个内部判定调用点全部切换到 `pointInSelectionRect`：
  按下分发的选区内判定 ×2 + deselectMode 外部判定 ×2。

## 边界

- 多元素选区的 `ftc.d` 旋转仅在「整体旋转」语境非零；Harmony
  无选区级旋转寄存器（元素各自 `rotationRadians`）→ 退回
  AABB，原版等效场景不可静态表达。
- 组选区成员旋转已烘进各自 `bounds` → AABB 等价。

## 验证

- 新增 replay `d02-original-rotated-selection-hit-test.mjs`：17/17 绿。
- 全量 desktop replay 套件：509/509 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误（修复过程中出现的
  obj-literal-as-type / union 收窄错误已就地修正）。
- 未启动模拟器/真机/Hypium。

## 提交

Phase 619 commit（见 git log）。
