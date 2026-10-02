# Phase 1464 报告：guf.h 文本 16px 下限扩展到 isf/jsf 逐成员钳制

## 原版行为（1.4.2 证据）

`guf.h(Map map, float f, float f2, long pivot, boolean z)`
（guf.java:280-354）是 wtf 缩放会话的应用函数，对 map 中
**每个成员独立**决定有效缩放：

- `jv6` 文本成员：由 `pfgA`（文本框尺寸）与 `hv6.b()`（现有
  变换轴幅）逐轴计算地板
  `fD2 = max(f, 16/(框宽·现有X幅))`、`fC2 = max(f2, 16/(框高·现有Y幅))`；
- 非 `jv6` 成员：`pfgA==null` → 不钳制，直接乘请求比；
- 成员间可分歧——含文本块的 isf 套索选区整体缩小时，各文本
  成员各自停在自己的 16px 地板，其余成员照缩；
- `z=true`（提交支）附带 `a()` 跨页迁移（P1459 已 fail-closed）。

`h` 同时服务锁定比路径（locksAspectRatio 只是求值方式——locked
时 sx==sy==s），故 isf/jsf 多选含文本成员时地板照样逐成员生效。

## Harmony 缺口（Phase 1459 登记）

P1459 只在 `resizeFreeScale`（lsf 单文本自由拉伸）支实现选区级
钳制；锁定比路径（isf/jsf 含文本成员）无地板——套索选中
"文本块+图形"整体缩小会把文本压成不可读小框。

## 实现（NoteCanvasView.ets）

- `applySelectionResize` 锁定比支：`applySelectionTransform` 后调
  `applySelectionTextFloor(scaleX, scaleY)`。
- `applySelectionTextFloor`：
  - 遍历 `selectedTextBlockIds`，基准取 `dragBeforeTextBlocks`
    会话前快照；现有轴幅 `ex=hypot(t[0],t[3])`、
    `ey=hypot(t[1],t[4])`（`hv6.b()` 等价）；
  - `floor_i = 16/(blockDim·existing_i)`；逐轴校正
    `c_i = max(1, floor_i/s)`；
  - 校正矩阵 `C_i = T(anchor)·R(θshell)·diag(c_ix,c_iy)·
    R(−θshell)·T(−anchor)`（θshell=`resizeShellRadians`；
    θ=0 退化轴对齐），左乘成员 `transform` 并同步
    `transformBounds`；非文本成员不动；
  - 有校正时 `updateSelectionOverlay` + `renderFrame` 刷新。
- freeScale 支维持 P1459 选区级钳制（lsf 单文本时逐成员≡全局）。

## 验证

- `d02-original-scale-session-wtf.mjs`：29→35 项（接线断言 +
  逐成员地板可执行模型：s=0.05 → c=1.6 校正；s=0.5 → 不校正）。
- `note@default` 构建通过；全量 Replay 与 `note@ohosTest` 收尾
  验证（本轮收尾时补入提交信息）。

## 遗留差异

- 校正叠加在选区级 `state.transform` 之上（Harmony 无逐成员
  缩放通道）——与原版"同函数内逐成员选比"数学等价（等比时
  完全一致），登记为实现路径差异而非行为差异。
- `guf.m`（utf 捏合）无 16px 地板——不覆盖，符合原版。
- 页界迁移 `a()` 仍按 P1459 fail-closed。
