# Phase 1467 — 旋转柄命中域 = 茎锚点方向性条带（ms1:667-683）

## 原版证据（decompiled_1.4.2）

### ms1.java onTouchDown 分发（约 L640-700）

套索/选区激活态下，down 触点依次裁决：角柄（f15 方框）→
**旋转柄** → 选区内 → 选区外。旋转柄命中块（ms1:667-683）解码：

```
// f5 = 触及(72+32)/zoom，f6 同轴方向（LTR + / RTL −）
// f21 = 端点半径 16/zoom，f4 = 过冲 32/zoom
锚点 = gsf.i(sbe, yj8)            // = (dir==LTR? sbe.c:sbe.a, (b+d)/2)
条带 = sbe(锚x, 锚x+f·104/zoom,   // f=+1 LTR / −1 RTL
           锚y−48/zoom, 锚y+48/zoom)
命中 = f5n.h(触点, 条带, 枢轴, θ)  // 触点绕枢轴反旋 −θ 后测 sbe 包含
```

- **触及 = (72+32)/zoom = 104/zoom**：茎 56 + 端点 Ø32（半径 16，
  72=56+16 恰为茎根到端点圆心外缘距离）+ 过冲 32 文档单位。
- **半高 = (16+32)/zoom = 48/zoom**：端点半径 16 + 过冲 32。
- **方向性**：条带自边中点锚**向柄侧**延伸——LTR 从右边向右
  `[anchor, anchor+104]`；RTL（yj8.G）从左边向左
  `[anchor−104, anchor]`。
- **旋转系判定**：`f5n.h` 先把触点绕框枢轴反旋回未旋转选区
  坐标系，再做轴对齐矩形包含——与 gsf.c 整框 `xke.s(center,θ)`
  绘制同系。

### 视觉对照（gsf.e:84-103）

绘制侧：茎 56/zoom + 端点双层圆 Ø32/Ø28。命中条带 104×96 明显
大于可视茎+端点（56+16=72 触及、Ø32 高）——**茎中段与端点周围
一整条带状区域均可启动旋转会话**，过冲 32 提供触达容差。

## Harmony 缺口（修复前）

`selectionRotateHandleAt` 只对**茎端点**做 Ø44vp 圆命中
（`Math.hypot(p−endpoint) <= SELECTION_HANDLE_HIT_RADIUS=22`）。
后果：触点落在茎中段（锚+0..72 区间、距端点 >22vp）时无法启动
旋转——比原版可达域窄得多。

## Harmony 对齐实现

`NoteCanvasView.selectionRotateHandleAt`（NoteCanvasView.ets:8219）：

```ts
const g = this.selectionChromeGeom();          // 未旋转壳框+θ
const q = this.unrotateChromePoint(p, g);      // f5n.h 等价：反旋入壳系
const anchorX = rtl ? g.rect.left : g.rect.right;   // gsf.i 锚边
const anchorY = (g.rect.top + g.rect.bottom) / 2;   // 边中点
const inX = rtl ? q.x ∈ [anchorX−104, anchorX]
                : q.x ∈ [anchorX, anchorX+104];
return inX && |q.y − anchorY| <= 48;
```

- `SELECTION_ROTATE_HANDLE_HIT_REACH = 104`、
  `SELECTION_ROTATE_HANDLE_HIT_HALF_H = 48`
  （SelectionOverlayLayout.ets:21-22），屏上 vp 与原版 dp/zoom
  在 zoom=1 屏系等价（既有铬件几何全部在屏 vp 系表达）。
- 反旋通道复用 Phase 1461 的 `unrotateChromePoint`（绕壳中心
  −θ），与原版 `f5n.h` 枢轴反旋一致。
- 移除死常量 `SELECTION_HANDLE_HIT_RADIUS`（端点圆命中专用，
  现由条带覆盖茎+端点+过冲）。

## 遗留差异

- 原版命中域随 `zoom` 反比缩放（`/zoom` 文档单位），Harmony
  常量在屏 vp 系固定——放大画布时 Harmony 条带相对文档元素更大
  （更宽松），与原版视觉柄本身放大同步，触觉体验等价。
- 端点正下方/上方的圆形过冲区（原版含在条带 ±48 内）已覆盖。
