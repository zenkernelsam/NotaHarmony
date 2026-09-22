# ADR-0593: 区域选择 inside 判定采用绘制矩形（ftc.a）而非成员 union

- 状态：已接受
- 日期：2026-09-28；Phase 624
- 证据：`docs/migration/evidence/original-drawn-rect-inside-check-2026-09-28.md`

## 背景

原版区域选择（套索/矩形）完成时，`uw2` case1 以
`new ftc(cmbVar, cmbVar, cmbVar, …)` 提交新壳——三个矩形字段
全部等于绘制区域 bounds，而非命中元素的 union。后续 `dl1`
的 inside 判定 `yxi.e(ftcVar.a, …)` 测的正是这个**绘制矩形**；
覆盖层显示则另用 `ftc.o`（成员 union）。Harmony 此前对所有
多元素选区一律用成员 union 做 inside 判定：绘制区覆盖成员
空隙时，空隙内按下被误判 outside → 取消选区，而原版进入
`wtc` 拖拽。

## 决策

1. `SelectionState` 新增 `drawnRect`（画布坐标）：`finalizeSelection`
   提交时存 `drawnBounds()` 克隆（套索=路径 bounds，矩形=绘制
   rect）；`selectElementIds`/`deselect`/`beginSelection` 置 null。
2. `drawnRectTransformed()`：绘制矩形按 `state.transform`（累积
   壳变换）做 4 角变换外接矩形——等价 `ftc.e` 把
   `qpi.b(this.b, transform)` 写回 `a`（旋转提交后 `a` 也是膨胀
   AABB，与 rebound 语义一致）。
3. `pointInSelectionRect`：`drawnRect!=null` → 投影屏幕后按
   `uniformSelectionCarrierRadians()` 反旋转 `-θ`（绕绘制矩形
   中心）做 yxi.e 等价包含测试；该分支在单元素元素命中之前
   ——只命中一个元素的 marquee 在原版同样产 `ftc`。
4. `drawnRect==null`（点选/全选/粘贴/itc/gtc）→ 既有元素命中
   与 uniform-rotation union 路径不变。
5. 覆盖层 `selectionRect` 仍用成员 union（`ftc.o` 等价）——
   原版判定矩形与显示矩形本来就是两个字段。

## θ 检测的已知边界（fail-closed）

`uniformSelectionCarrierRadians()` 只统计携带 `rotationRadians`
的成员（椭圆形状/文本/图片/数学块），笔画不参与——旋转已
烘进 path/bounds，壳层 θ 由可携带成员反映。纯笔画旋转选区
的 inside 判定按 θ=0 退化（绘制矩形不做反旋转）——与原版
`ftc.d` 壳寄存器在纯笔画场景的理论值存在偏差，属已登记
近似，不影响未旋转选区。

## 结果

- replay `d02-original-drawn-rect-inside-check.mjs`：20/20 绿。
- 关联 fixture（itc/rotated/deselect/tap-clear）全绿；全量
  套件 514/514 绿；双 HAP 构建绿。
