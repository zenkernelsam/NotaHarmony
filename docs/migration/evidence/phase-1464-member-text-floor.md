# Phase 1464 — guf.h 文本 16px 下限扩展到 isf/jsf 逐成员钳制

## 原版证据（decompiled_1.4.2/sources/defpackage/guf.java）

`guf.h(Map map, float f, float f2, long pivot, boolean z)`
（约 L280-354）——wtf 会话的应用函数，对 map 中**每个成员**独立
计算有效缩放：

- 成员为 `jv6`（文本块）时：`pfgA` = 文本框尺寸 +
  `hv6.b()` 现有缩放 → 逐轴地板
  `fD2 = max(f, 16/(pfgA.d·现有X幅))`、`fC2 = max(f2, 16/(框高·现有Y幅))`；
- 非 jv6 成员：`pfgA==null` → 直接乘请求比，不钳制；
- 成员间可分歧（每成员独立 floor_i）；
- `z=true`（提交支）附带 `a()` 页界迁移（P1459 已 fail-closed）。

调用链：wtf 会话 move → `guf.f`/锁定比求 (sx,sy) → `h(mapI, sx, sy,
pivot, z)`。**locksAspectRatio 只是求值方式**（locked 时 sx==sy==s），
`h` 对锁定比路径同样逐成员跑 jv6 地板——isf 多成员含文本块时地板
照样生效。

## 差距（修复前）

Harmony Phase 1459 只在 `resizeFreeScale`（lsf 单文本块自由拉伸）支
做了选区级钳制；锁定比路径（isf/jsf 含文本成员）无地板——isf 套索
选中"文本块+其它元素"整体缩到 16px 以下时，Harmony 会把文本压成
不可读小框，原版则只钳文本成员。

## Harmony 实现（本 Phase）

`applySelectionResize` 锁定比支在 `applySelectionTransform` 后调
`applySelectionTextFloor(sx, sy)`：

- 遍历 `selectedTextBlockIds`，基准尺寸取 `dragBeforeTextBlocks`
  会话前快照（`hv6.b()` 等价——成员现有轴幅
  `hypot(t[0],t[3])`/`hypot(t[1],t[4])`）；
- `floor_i = 16/(blockDim·existing_i)`；逐轴 `c_i = max(1, floor_i/s)`；
- 命中成员变换后乘校正矩阵
  `C_i = T(anchor)·R(θshell)·diag(c_ix,c_iy)·R(−θshell)·T(−anchor)`
  （θshell=`resizeShellRadians` 铬件壳旋转；θ=0 退化为轴对齐），
  `transform`/`bounds` 同步校正；非文本成员不动。
- 校正后 `updateSelectionOverlay` + `renderFrame` 刷新。

freeScale 支维持选区级钳制（lsf 单文本时逐成员=全局，等价）。

## 验证

- `d02-original-scale-session-wtf.mjs` 扩至 35 项（成员级钳制接线 +
  逐成员地板模型：s=0.05 → c=1.6 校正；s=0.5 → 不校正）。
- 全量 Replay 1304/1304；双 HAP 构建通过。
