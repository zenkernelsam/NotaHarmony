# ADR-0565 — 选区覆盖层角柄自由变换（htc.e / qpi.b / fvb.f）

- 状态：Accepted
- Phase 596；对齐 `htc.e`/`gtc.e`/`qpi.b`/`fvb.f`/`avc`（decompiled_1.0.3）。

## 背景

原版选区覆盖层是可变换的：`htc.e(commit, translate, scale, rotation,
pivot)` 由手势驱动，`qpi.b` 以 **pivot 等比缩放 + 平移**构矩阵，
**旋转角单独累加**并于渲染时绕新矩形中心（`fi3.b(cmb)`）应用；
`z` 区分预览/提交。手势产出端（`avc:689`）一次给出
scale + rotation + pivot——即角柄拖拽 = 距离比缩放 + 绕锚点角位移
旋转的自由变换。

Harmony 的 `SelectionOverlay` 此前只有虚线框 + 菜单；
`SelectionTool.scaleSelected`/`rotateSelected` 是死代码——选区
不能缩放/旋转，是明显的行为缺口。

## 决策

1. `SelectionOverlay` 四角绘制 12vp 角柄圆点（`SELECTION_HANDLE_SIZE`，
   命中半径 22vp），deselectMode / 照片导入租约时隐藏。
2. `onTouchDown` 角柄命中**先于**内部拖拽分支；命中进入
   `selectionResize` 会话：`anchor` = 对角画布坐标（原版 pivot 语义），
   `resizeStart` = 按下角点，`resizeBaseTransform` = 起始矩阵快照，
   `resizeBaseCenter` = 起始选区中心；`positionLocked` 时不产出。
3. 每帧重建（对齐 `qpi.b` 非增量语义）：
   `scale = dist(p,anchor)/dist(start,anchor)`；
   `θ = angle(p−anchor) − angle(start−anchor)`；
   `scaledCenter = anchor + scale·(baseCenter−anchor)`；
   `transform = R(scaledCenter,θ) · S(anchor,scale) · base`
   （`SelectionTool.resizeSelected`）。
4. 提交/取消复用 `selectionDrag` 通道：`dragBefore*` 快照、
   `TRANSFORM_ELEMENTS` 单次撤销、`cancelActiveInteraction` 恢复。

## 偏差（fail-closed 记录）

1. 原版覆盖层矩形随旋转角倾斜（cmb 四角逐帧变换），角柄落在
   旋转后矩形角上；Harmony `selectionRect` 是轴对齐包围盒——
   旋转后角柄落在包围盒角而非元素角上。功能等价（仍可继续
   缩放/旋转），锚点几何在已旋转选区上不同。
2. 原版的专用旋转柄（`msc.c` selectionHasRotationHandle）未单独
   移植——角柄拖拽已产出旋转（角位移非 0 即旋转），覆盖同一
   变换维度；专用柄属后续 UI Phase。
3. 缩放为等比（`y18.f(s,s)` 原版亦等比）；原版的非等比边柄
   （若存在）未覆盖。
4. 平移（`ei3Var` 分量）已由内部拖拽通道覆盖，本项不重复。

## 验证

- `docs/migration/replays/d02-original-selection-resize.mjs` 24 项断言
  （角柄门控/锚点/数学/提交通道 + 可执行数学模型）。
- 证据：`docs/migration/evidence/original-selection-resize-2026-09-23.md`。
