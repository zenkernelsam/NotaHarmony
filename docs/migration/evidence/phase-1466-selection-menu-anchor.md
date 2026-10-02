# Phase 1466 — 选区动作菜单侧锚定位（mnm.c → abn.e → i3b）

## 原版证据（decompiled_1.4.2）

### 锚矩形生产链（mnm.java:158-185，y3b=ShowSelectionMenu 支）

1. `y3b(bounds=sbe, msf)`（y3b.java）携**选区 sbe 矩形**（轴对齐
   DocPxRect——旋转选区的 sbe 即旋转内容的包容 AABB）。
2. `mfc.n(sbe)`（mfc.java:394-401）：`u64.h(sbe, k())` 文档单位×缩放
   →屏 px `ku7`，减画布原点 `o()` 得屏上锚框。
3. `odf.c(ku7, 72, 72)`（odf.java:20-22）：**四边各膨胀 72 屏 px**
   ——恰好等于旋转柄触及区（茎 56+端点 16=72），菜单不与旋转柄
   冲突。
4. `abn.e(ku7Var2, …)` → `abn.c`（abn.java:157-223）：锚框再平移
   `−(WindowInsets + 12dp)`，包装内容补 `insets+12dp` 填充，
   `i3b(yj8, ku7Var2, iM0=12dp)` 为弹层定位器。

### i3b.java measure — 定位裁决

- `ku7Var` = 膨胀锚框（a=left, c=right）；`i7` = 容器最大宽；
  `i8` = 12dp(px) 边距。
- **LTR（yj8.F）**：`i9 = c + margin` → 菜单面板贴锚框**右缘**；
  `i9+菜单宽 > 容器宽` 溢出 → `i2 = a − 菜单宽 − margin`（左缘）；
  仍溢出 → `i7 − 菜单宽`（容器右缘夹取）。
- **RTL（yj8.G）**：镜像坐标计算——主侧 = 锚框左缘，回退右缘。
- **纵向**：`odf.a(ku7)` = `((a+c)/2, (b+d)/2)` 锚框中心点；
  `y = 中心y − 菜单高/2` 夹取 `[0, maxH − 菜单高]`——**纵向居中**
  于选区。
- 菜单是整列弹层面板（非先按钮再下拉），项宽/高取测量值。

## Harmony 缺口（P1461 登记「菜单锚仍 AABB」）

`selectionOverlayPosition` 把菜单按钮钉在 `rect.left`（左对齐）+
`rect.bottom + 8`（下挂）——既不跟选区侧缘，也不垂直居中，且没有
旋转柄清除区（选区旋转后柄伸出右侧会与菜单重叠）。

## 实现（SelectionOverlayLayout.ets + 接线）

`selectionOverlayPosition(rect, cw, ch, hasPaste, rtl)` 重写为 i3b
语义：

- `inflate = px2vp(72)`（72 屏 px → vp，`odf.c` 等价）；
- LTR：`x = rect.right + inflate`；`+W > 容器宽` →
  `rect.left − inflate − W`（`>=0` 才采纳）；仍溢出 → 右缘夹取；
- RTL 镜像（主侧左缘）；
- `y = (rect.top+rect.bottom)/2 − 菜单组高/2` 夹取
  `[8, 容器高−8−组高]`；
- `SelectionOverlay` 按钮 `.position` 与 `isInSelectionMenu` 命中
  共用同一布局函数并透传 `selectionRotateHandleRtl`（`yj8` 等价）。

## 差异说明

- 原版菜单为整列弹层面板，Harmony 为「按钮 + bindMenu 下拉」
  （T-033 已登记的 ArkUI 适配）——本 Phase 使按钮/弹层锚点与
  原版弹层面板锚点对齐。
- 窗口 insets 与 12dp 微边距在 Harmony 全屏覆盖层坐标系下退化
  （登记：insets 未扣减，全面屏差异 ≤ 数十 px）。
- 锚 sbe 在 Harmony 侧 = `selectionRect`（成员变换后并集 AABB，
  已随旋转膨胀），与原版 `mfc.n(sbe)` 语义一致。

## 验证

- 新 fixture `d02-original-selection-menu-anchor.mjs`：14 项
  （锚膨胀/侧向裁决/RTL 镜像/纵向居中/接线 + 6 项可执行模型）。
- `note@default` 构建通过；全量 Replay 与 `note@ohosTest` 收尾验证。
