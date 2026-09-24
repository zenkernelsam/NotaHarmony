# Phase 677 证据：原版 POINTER（多人光标）/ ZOOM 工具与 view-only 门控 —— fail-closed 登记

## 原版证据（decompiled_1.0.3）

### 工具枚举全貌

`a6f.java` 13 工具：PEN(0)/PENCIL(1)/HIGHLIGHTER(2)/TEXT(3)/ERASER(4)/
SELECT(5)/MEDIA(6)/RECORD(7)/**POINTER(8)**/LASER(9)/REVIEW(10)/
RULER(11)/**ZOOM(12)**。

`rz1.java` 默认工具箱种子：

- `q()` 主托盘：PEN(id1)/PENCIL/HIGHLIGHTER/ERASER/TEXT/SELECT/
  MEDIA/RECORD。
- `r()` 次托盘：`u5f(10,1,a6f.Q,0,null)` = **POINTER(tool_id=10,
  tray1 index0)**、LASER(index1)、ZOOM(index2)、REVIEW(index3)、
  RULER(index4)。

`s01.a0()` 工具箱列表过滤：

- `a6f.T`(RULER)：无条件剔除 —— 1.0.3 隐藏工具。
- `a6f.U`(ZOOM)：仅 `lc4.a(ac4.e0)`(ZOOM_VIEW 远程旗标) 时保留。
- `a6f.S`(REVIEW/tape)：仅 `lc4.a(ac4.t0)` 时保留（Harmony 已实现）。
- `a6f.Q`(POINTER)：不在 a0 过滤中 —— 正常模式出现在工具箱。

### POINTER = 多人 presence 光标工具

- `c59.java`：`ac4.b0`(VIEW_ONLY) 旗标评估每笔记 view-only 状态流。
- `s01.b0(list, isViewOnly)`：view-only 时把 POINTER 从工具箱列表
  剔除；`s01.X(isViewOnly, tool)`：`!isViewOnly || tool==POINTER` ——
  **view-only 模式全工具箱禁用，POINTER 是唯一放行工具**。
- `ti9.l0 = ys2.P(a6f.Q)`：POINTER 属于"无可视配置瞬态工具"集合
  （`ti9.p` 放行条件）。
- `dg9.java` case 0（eg9 收集 `ti9.V` 编辑许可流）：编辑许可
  `V.I` 变 false → `i8f.i(a6f.Q)` **自动切到 POINTER** —— 进入
  view-only 时强制换工具。
- `wda.java`/`zda.java`/`aea.java`/`gm.java`/`mzc.java`：presence
  协议层 —— `wda`(参与者: id/名/颜色/`zda`)，`zda`(位置+工具
  `u76`+边界)，`aea`(presence 更新消息)，`gm`/`mzc`(会话协议)。
  `zda.f` 默认工具即 `u76.POINTER`。
- `l96.java`：远端参与者光标渲染 —— 按 `zda` 工具取
  `ui_designsystem__presence_pen`/`_highlighter`/`_cursor` 图标绘制。
- `sva.java`/`tzc.java`：`ac4.c0`(MULTIPLAYER_PRESENCE) 门控
  presence 会话（`tzc` "Creating session" + `note.id`）。
- `w4g.a`：POINTER `Float[0]` —— 无笔宽档；`y5f` c5f→a6f.Q 无
  e31 视觉配置；`b7f` 收藏栏 `c5f` 行。

**结论**：POINTER 的真实功能是向协作会话参与者广播光标位置
（`zda` 经 `aea`/`gm`/`mzc` 协议同步，`l96` 在远端渲染），
并作为 view-only（只读）笔记的唯一可用工具。两者都依赖
`ac4.c0`(多人 presence 会话) / `ac4.b0`(VIEW_ONLY) 服务端协作域。
无会话时该工具不产生任何可见输出（远端列表为空、无本地渲染
消费者）。

### ZOOM = ZOOM_VIEW 旗标门控

- `a6f.U` + `x82` case 12 → `ui_tools__zoom`("Zoom")；
  `rz1.r()` 次托盘 index2；`w4g` 无宽度档；`y5f` case 12 无视觉。
- `s01.a0` 仅当 `lc4.a(ac4.e0)` 保留 —— `ac4.e0` = ZOOM_VIEW
  （`zb4.L` 远程配置通道，`ztb.c="androidZoomView"`），1.0.3
  静态态无法证明开启；按旗标未开处理。

## Harmony 侧判定

- 多人协作/presence 会话：不存在（无账号/会话后端）→ POINTER
  的可观察行为全部为服务端域 → **fail-closed 不移植**。在
  `ToolRepositoryImpl` 次托盘 index0 继续留空（与原版 `b0` 在
  view-only 剔除 POINTER 的表面一致）；不渲染死按钮。
- ZOOM_VIEW 远程旗标在 1.0.3 未开 → ZOOM 不移植，index2 留空。
- RULER 已由 `s01.a0` 无条件隐藏 → 不移植（ADR-0642 已登记），
  index4 留空。
- view-only/多人 presence 体系整体属协作服务端域 → 整体登记为
  服务端 fail-closed（与 LINK 分享同一处置）。

## 验证

- `d02-original-presence-zoom-tools-failclosed.mjs`：原版证据
  锚点 + Harmony 侧 absence/留位注释断言。
- 全量 Replay 与双 HAP 构建随本阶段通过。
