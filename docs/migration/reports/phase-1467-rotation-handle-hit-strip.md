# Phase 1467 报告：旋转柄命中域 = 茎锚点方向性条带

## 原版行为（1.4.2 证据）

`ms1` onTouchDown 命中分发（ms1:664-683）：旋转柄命中域为
**自选区边中点锚向柄侧延伸的条带矩形**，而非端点圆——

- 锚点 `gsf.i(sbe, yj8)`：LTR 取右边中点 `sbe.c`，RTL 取左边
  中点 `sbe.a`；
- 触及 `(72+32)/zoom = 104/zoom`：茎 56 + 端点圆半径 16（72 即
  茎根到端点圆心外缘）+ 过冲 32；
- 半高 `(16+32)/zoom = 48/zoom`：端点半径 16 + 过冲 32；
- 判定 `f5n.h`：触点绕枢轴反旋回未旋转选区系后做轴对齐矩形
  包含——与 `gsf.c` 整框旋转绘制同系。

即：**茎中段、端点及周围整条约 104×96 条带均可按下启动旋转
会话**。

## Harmony 缺口

`selectionRotateHandleAt` 仅对茎端点做 Ø44vp 圆命中——茎中段
（锚点与端点之间约 60vp 区间）触点完全落空，旋转手柄可用触达域
远小于原版。

## 实现

- `SelectionOverlayLayout` 新增
  `SELECTION_ROTATE_HANDLE_HIT_REACH = 104` /
  `SELECTION_ROTATE_HANDLE_HIT_HALF_H = 48`；
  删除死常量 `SELECTION_HANDLE_HIT_RADIUS`。
- `selectionRotateHandleAt`：`selectionChromeGeom()` 取未旋转壳框
  → `unrotateChromePoint` 反旋触点 → 锚 = `rtl ? left : right`
  边中点 → `q.x ∈ [anchor, anchor+104]`（RTL 镜像
  `[anchor−104, anchor]`）且 `|q.y − anchorY| ≤ 48`。

## 验证

- 新 fixture `d02-original-selection-rotate-hit.mjs`：18 项——
  常量/结构 pin + 可执行条带模型：LTR 茎中点命中（旧圆不覆盖）、
  条带两端含端点、界外/选区内拒绝、±48 垂直边界、RTL 镜像双侧、
  旋转壳 +30° 轴上点命中/屏轴离轴点拒绝。
- `d02-original-selection-handle-geometry.mjs` 命中域断言更新为
  条带 pin（22 项）；`d02-original-selection-resize.mjs` 死常量
  pin 移除（36 项）。
- `note@default` 构建通过；全量 Replay 与 `note@ohosTest` 收尾
  验证。

## 遗留差异

- 原版条带为 `/zoom` 文档单位（缩放时屏上恒定），Harmony 为屏
  vp 常量——zoom>1 时相对文档坐标更宽（宽松方向），与视觉柄同步
  放大后的触达预期一致，登记为可接受适配差异。
