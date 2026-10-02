# Phase 1449 报告：成员级选区铬件渲染对齐

## 原版行为（1.4.2 反编译证据）

选区铬件 = 成员级（`s40.c`）+ 外层级（`gsf.h`）：

- **成员路径轮廓**（`qmm.d`）：笔画/形状成员按**实际路径**（非包围盒）
  以 `#FF4278FF` 描边，宽 `min(2dp/zoom, strokeWidth/2)`，线宽在元素
  变换前设定（随矩阵缩放）。
- **成员框**（`xnm.c`+`gsf.c`）：仅图片/文本成员产旋转矩形框，2dp/zoom
  实线蓝；`lsf` 且成员未锁（`!mp4.d()`）时框带柄。
- **外层界**（`gsf.h`）：`lsf` 早退无外框；`jsf` 组点选 =
  `#FFB3B3B3` 灰实线 2dp 外盒+柄；`isf` 绘组灰盒+外柄（deselectMode
  去柄）。
- `sen.d` 对 lsf/jsf 不产画布界框（只挂重组回调）。

## Harmony 缺口（修复前）

- 成员级铬件整体缺失——选中笔画/形状只见矩形界而非轮廓；
- lsf 单元素点选显示蓝色外框（原版无）；
- jsf 组点选显示蓝虚线界（原版灰实线）；
- lsf 恒显手柄（原版仅未锁图/文成员框带柄）。

## 本次改动

- `NoteCanvasView.renderSelectionMemberChrome()`：画布变换块内
  （元素层之上、外层界之下）成员铬件——笔画 `customPath??fillPath`
  轮廓（缺省中心线）、形状 `shapeWorldSubpaths` 子路径、图/文旋转
  成员框、组灰盒（`memberUnionBounds`）。
- `ShapeGeometry.shapeWorldSubpaths`：新增导出（分路径世界坐标，
  防多子路径压平连线）。
- `SelectionOverlay`：`selectionBorderless`（lsf 隐外框）、
  `selectionOuterGray`（jsf 灰实线 2dp）、`selectionHandlesHidden`
  （lsf 非框化成员/已锁成员隐手柄）。
- 镜像赋值在 `updateSelectionOverlay`。

## 验证

- 新增 fixture：`d02-original-member-chrome-render.mjs`（21 断言）；
  更新 `d02-original-selection-outline-render.mjs` 界式样断言。
- 证据：`evidence/phase-1449-member-chrome-render.md`；ADR-1384。
- 登记差异：组灰盒轴对齐（无 `tof.g()` 旋转）；形状顶点圆点未移植；
  线宽随矩阵列模缩放为近似。

## 结果

全量 Desktop Replay 基线、`note@default`、`note@ohosTest` 见提交信息。
