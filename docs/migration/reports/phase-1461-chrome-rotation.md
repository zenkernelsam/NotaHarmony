# Phase 1461 报告：选区外铬件壳旋转（gsf.c xke.s(center,θ) 渲染 + ms1 旋转系命中 + wtf 旋转系轴）

## 原版行为（1.4.2 证据）

- `gsf.c(qe4, mp4, f2, z, j)`（gsf.java:44-63）：绘制外铬件前
  `xke.s(mp4.b(), mp4.c())` 把画布绕 **sbe 中心**旋转 mp4 角度，
  然后画 2dp 实线界、`gsf.e` 茎柄、`gsf.b` 四角柄——**界+柄整体
  旋转**。
- `gsf.h`（gsf.java:122-160）：isf 支壳角=`isfVar.d`、jsf 支壳角=
  `jsfVar.g()`（组选区携带 Float 旋转）；lsf/hsf 无外盒早退。
- `isf.e()` 提交支把变换后的壳角写回 `d`/`e`——旋转会话后外盒
  保持旋转，重选重建 isf 归零（`z6c` case6 `new isf(...)` d=null）。
- `ms1:295-327`：角柄/茎柄命中在旋转系内进行（kw9.c 旋入后
  ±f15=44/zoom 轴对齐方框）。

## Harmony 缺口（Phase 1449/1450 登记）

覆盖层外盒+角柄+茎柄恒按 AABB `selectionRect` 渲染；命中亦按
AABB——与已移植的 `yxi.e` 旋转系 inside 判定（触点反旋 −θ）不对称：
旋转选区界内点按旋转壳判 inside，铬件却画轴对齐框且柄错位。

## 实现

1. **壳几何**：复用 `uniformRotationUnrotatedScreenRect()`（统一旋转
   成员的去旋并集屏框 + θ——`isf.d`/`jsf.g` 等价源）。新增
   `selectionChromeGeom()`：u≠null → {u.rect, u.radians}；否则
   {selectionRect, 0}。
2. **渲染**：SelectionOverlay 新增 `selectionChromeRect`/
   `selectionChromeRadians` props；界+四角柄+茎柄画在未旋转壳框上，
   外层 Stack `.rotate(angle, centerX/Y=框心)` —— `xke.s` 的 ArkUI
   等价（先画未旋转再旋）。菜单锚仍用 `selectionRect` AABB。
3. **命中**：`unrotateChromePoint()` 触点绕框心反旋 −θ；
   `selectionRotateHandleAt`/`selectionResizeCornerAt` 在未旋转壳上测；
   `selectionScreenCorners()` 产旋转后屏角。
4. **wtf 旋转系轴**：`resizeAxisVecX/Y` = 对角 D 分解到框轴单位
   向量（`wtf.xAxis/yAxis`）；`resizeSelectedAxes` 增 `shellRadians`
   参数——θ≠0 时 `R(θ)·diag(sx,sy)·R(−θ)` 共轭缩放矩阵，
   freeScale 旋转壳沿框轴正确双轴缩放；AABB 下退化为旧标量式。
   `resizeShellRadians` 在会话建立时捕获。

## 验证

- fixture 更新：d02-original-scale-session-wtf（29 项，新增旋转壳
  轴分解+共轭矩阵可执行模型）、d02-original-selection-handle-geometry
  （21 项，新增壳旋转渲染/命中断言）、d02-original-selection-resize
  （36 项，pin 更新）、d02-original-rotated-selection-hit-test（18 项
  未破）。
- `note@default` HAP 构建成功（CompileArkTS 28.5s 无错误）。
- 全量 Desktop Replay 基线待跑。

## 差异登记

- 含笔画选区壳旋转不生效（笔画旋转烘进 pathPoints 无载体）——
  与 yxi.e 命中模型同源缺口。
- `jsf.g()` 组持久旋转以成员叶子公共旋转代理。
- 菜单锚保持 AABB 顶中。

证据：`docs/migration/evidence/phase-1461-chrome-rotation.md`；
ADR：`docs/migration/adr/ADR-1396-chrome-rotation.md`。
