# ADR-1402: 旋转柄命中域 = 茎锚点方向性条带矩形（ms1:667-683 移植）

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1467
- **关联**: evidence/phase-1467-rotation-handle-hit-strip.md
  （`ms1` 命中分发 / `gsf.i` 锚点 / `f5n.h` 反旋解码）

## 背景

原版旋转柄的触摸命中域不是围绕端点的圆——`ms1` down 分发构造
一条自选区边中点锚**向柄侧**延伸的方向性矩形条带：
`[anchor, anchor±104/zoom] × [midY−48/zoom, midY+48/zoom]`，
触点先经 `f5n.h` 绕枢轴反旋入未旋转选区系再判定。条带完整覆盖
茎 56 + 端点 Ø32 + 过冲 32 的全部触达区。

Harmony 此前（Phase 1450/1461）只测试茎端点 Ø44vp 圆——茎中段
触点不命中，旋转会话启动域比原版窄。

## 决策

`selectionRotateHandleAt` 重写为条带语义：

1. `selectionChromeGeom()` 取未旋转壳框+旋转角；
2. `unrotateChromePoint(p, g)` 把屏触点反旋入壳系（`f5n.h` 等价）；
3. 锚 = 右（LTR）/左（RTL，`yj8` 方向）边中点；
4. `q.x ∈ [anchor, anchor+104]`（RTL 镜像 `[anchor−104, anchor]`）
   且 `|q.y − anchorY| ≤ 48`。

新常量 `SELECTION_ROTATE_HANDLE_HIT_REACH=104` /
`SELECTION_ROTATE_HANDLE_HIT_HALF_H=48`；删除死常量
`SELECTION_HANDLE_HIT_RADIUS`。

## 等价性与边界

- 旋转选区下命中域随壳旋转（反旋判定），与 `gsf.c`/`xke.s`
  整框绘制同系——无需另维护旋转命中区。
- 屏 vp 常量对应原版 dp/zoom 在 zoom=1 的等效值；高倍缩放时
  Harmony 条带相对文档略宽（更宽松，非更窄），接受为适配差异。
- 角柄（f15 方框）与菜单锚（odf.c 72px 膨胀）不受影响。

## 验证

- `d02-original-selection-rotate-hit.mjs`：18 项——常量 pin、
  实现结构 pin、可执行条带模型（LTR/RTL 茎中段命中、界外拒绝、
  ±48 边界、旋转壳反旋命中/离轴拒绝）。
- `d02-original-selection-handle-geometry.mjs`：22 项同步更新。
- 全量基线 1306/1306；clean `note@ohosTest` 与 `note@default`
  构建通过。
