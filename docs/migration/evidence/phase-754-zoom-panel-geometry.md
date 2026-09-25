# Phase 754 证据：Zoom 面板原版几何——画布卡 272dp + 控制条内沿序交换

> 证据基线：`decompiled_1.0.3`（JADX 输出，`C:\Users\Cisco He\Desktop\Notability\` 只读）。
> 关联：ADR-0695（747 初版面板）、ADR-0700（752 夹取域+翻转）、
> ADR-0702（本 Phase 决定）。

## 1. 原版结构（fgg.java）

`fgg.b`（decompiled_1.0.3/sources/defpackage/fgg.java:74-201）：

- `ggg.b == qeg.I` → `z2`（顶停靠）；`i4 = z2 ? 1 : -1`（位移动画符号）。
- `z5c.H(pd8VarThen, bgg(i4, l6aVar, l6aVar2))` + `fad.I`：拖拽重定位
  + 动画修饰符（hhf 速度甩动/egg panelInTopHalf 写入链）。
- `l96.J(z3=isShown, ..., ky3VarA/c44VarA, cgg)`：**AnimatedVisibility**，
  `s01.Y(500, 0, iq2, 2)` 500ms 滑入/滑出过渡。
- `cgg` Column（`ay1.a(g80.c, is1.V)`）内：
  ```java
  if (z5) { /* skip */ } else { fgg.a(ahgVar4, ix4Var, ...); }   // !top → bar 先
  njj.d(bfd.h(bfd.f(md8Var, 1.0f), 272.0f), ..., dgg);            // 画布卡 272dp
  if (z5) { fgg.a(ahgVar4, ix4Var, ...); }                        // top → bar 后
  ```
  即：**控制条恒贴面板内沿**——底停靠 `[bar][画布卡]`、顶停靠 `[画布卡][bar]`。

- `njj.d(fillMaxWidth().height(272.0f), color=surface, shape=rounded)`
  仅包 `dgg` = `Box{ j0j.a(放大表面 weight fill) + g0j.c(前进区覆盖层:
  前进宽 pill 20% alpha + 拖柄 htd→setAdvanceRegionWidth) }`。
  控制条 `wfg.d`（fgg.a 调用点 :63）是 Column **兄弟节点**，不占 272dp。

## 2. Harmony 偏差（Phase 747/752 遗留）

1. `ZOOM_SURFACE_HEIGHT_VP = 160` —— 无原版依据的缩水（原版 272dp）。
2. Phase 752 把 `panelInTopHalf` 机制实现为控制条 `scaleY=±1` 图标镜像——
   `svf` 的 `"toolboxFlip"` 作用于主工具条，Zoom 面板的实际机制是
   `fgg.b` 的 **Column 序交换**；镜像会把 ≡‹›↩✕ 字形倒置，非原版。

## 3. Harmony 修复（NoteZoomView.ets / NoteCanvasView.ets）

- `ZOOM_SURFACE_HEIGHT_VP: 160 → 272`（vp 等价 dp）；`surfaceHeightVp`
  默认 272。
- 控制条/画布区抽为 `@Builder ControlBar()` / `SurfaceArea()`；
  `build()` 按 `dockBottom` 交换顺序：底停靠 `[ControlBar][SurfaceArea]`、
  顶停靠 `[SurfaceArea][ControlBar]`。
- 删除 `scale({x:1,y:dockBottom?1:-1})` 镜像（机制证伪）。

## 4. 文件清单

- `note/src/main/ets/ui/editor/NoteZoomView.ets`：builder 抽取 + 序交换 +
  镜像删除 + 默认高 272。
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`：`ZOOM_SURFACE_HEIGHT_VP=272`。
- `docs/migration/replays/d02-original-zoom-view.mjs`：`h160→h272`、
  `p752.chromeflip.scale` 钉撤除、+6 条 p754 钉。
