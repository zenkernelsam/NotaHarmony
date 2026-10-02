# ADR-1384: 成员级选区铬件（s40/qmm/xnm 路径轮廓与成员框、gsf.h 外层界分源）

## 状态

已接受（2026-08，Phase 1449）

## 背景

1.4.2 选区铬件分两层：

- **成员级**（`s40.c`）：对每个选中成员绘铬件——`qmm.d` 把笔画 `mn7`/
  形状 `f5g` 成员的**实际路径**以 `gsf.a=#FF4278FF` 描边
  （宽 `min(2dp/zoom, strokeWidth/2)`，矩阵前施加故随变换缩放）；
  `xnm.c` 为图片 `l97`/文本 `vvh` 成员产 `mp4` 旋转框，经 `gsf.c` 绘
  2dp/zoom 实线蓝框，`z(lsf)&&!mp4.d()` 时带柄。数学块无成员铬件。
- **外层级**（`gsf.h`）：`lsf`/`hsf` 早退**不产外框**；`jsf` 组点选绘
  `c(jsf.a(), 2dp, e=#FFB3B3B3)` 灰实线外盒+柄；`isf` 绘 `f(m)` 组灰盒
  + `!h`（非 deselectMode）时外柄。

Harmony 此前对所有选区一律 `#FF4278FF` 覆盖层界+恒显手柄，成员级铬件
完全缺失——点选单笔画只见矩形界（原版是笔画轮廓）、点选组是蓝界（原版
灰界）、lsf 有外框（原版无）。

## 决策

1. **`renderSelectionMemberChrome`**（NoteCanvasView，元素层之上、
   sen 界之下）：
   - 笔画成员：`customPath ?? fillPath` 实轮廓（缺省中心线），
     `min(2dp/zoom, brushWidth·‖M‖/2)` 描边；
   - 形状成员：`shapeWorldSubpaths`（新增导出，子路径级防压平连线），
     同宽规则；
   - 图片/文本成员：`textBlockWorldCorners` /
     `imageBlockLocalBounds×transform` 旋转实线框 2dp/zoom；
   - 组（`selectedGroupIds`，覆盖 jsf 与 isf.m）：逐组
     `memberUnionBounds` → `#FFB3B3B3` 实线盒。
2. **覆盖层三 prop**：`selectionBorderless`（lsf=¬isf∧无组→隐外框）、
   `selectionOuterGray`（jsf=¬isf∧有组→灰实线 2dp）、
   `selectionHandlesHidden`（lsf 且唯一成员非未锁图/文→隐手柄，
   对应 `mp4.d()` 锁抑制与无框成员）。
3. lsf 图片/文本成员的"成员框+柄" = 画布层旋转框 + 覆盖层角柄（位于
   selectionRect 即成员界上），视觉与原版 gsf.c 等价。

## 登记差异

- 组灰盒为轴对齐并集（Harmony 组无 `tof.g()` 旋转存储）。
- `qmm.d` 形状成员顶点圆点（`cpfVar.g`）未移植——后续候选。
- 矩阵线宽缩放取 `hypot(m[0],m[3])` 列向量模（各向异性时近似）。

## 验证

- Fixture：`docs/migration/replays/d02-original-member-chrome-render.mjs`
  （21 断言：铬件函数/笔画轮廓/形状子路径/图文成员框/组灰盒/三 prop 门）。
- 证据：`docs/migration/evidence/phase-1449-member-chrome-render.md`。
