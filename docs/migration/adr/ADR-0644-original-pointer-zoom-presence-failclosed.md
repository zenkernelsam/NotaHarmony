# ADR-0644 — 原版 POINTER（presence 光标）/ ZOOM / view-only 门控：fail-closed 登记

日期：2026-09-24
状态：已登记（3 项服务端/旗标域 fail-closed；无源码行为变更）

## 背景

`a6f` 13 工具中 Harmony 缺 POINTER(8)、RULER(11)、ZOOM(12)。
逐项审计结论：

- **RULER**：`s01.a0` 无条件隐藏 —— 1.0.3 原版即不可见，
  Harmony 同样不暴露（ADR-0642 已登记 rulerUnits 偏好行）。
- **ZOOM**：`s01.a0` 仅 `lc4.a(ac4.e0)`(ZOOM_VIEW 远程旗标)
  时保留 —— 旗标功能，1.0.3 未开。
- **POINTER**：正常模式在次托盘 index0（`rz1.r` `u5f(10,1,
  a6f.Q,0,null)`），但其可观察功能 = 把本地光标位置广播给
  协作会话参与者（`zda`→`aea`→`gm`/`mzc` 协议，`l96` 以
  presence_cursor 图标渲染远端光标），并作为 view-only 笔记
  的唯一工具（`s01.X`/`s01.b0`/`dg9` 自动切换）。会话层由
  `ac4.c0`(MULTIPLAYER_PRESENCE) 与 `ac4.b0`(VIEW_ONLY)
  门控 —— 服务端协作域。

## 决策

1. **POINTER 不移植**：无协作会话后端时该工具无任何可见
   输出（无本地渲染消费者、远端列表为空）；渲染死按钮反而
   偏离原版语义。次托盘 index0 继续留空，与原版 view-only
   剔除 POINTER 的表面一致。
2. **ZOOM 不移植**：远程旗标在 1.0.3 未开；index2 留空。
3. **view-only / multiplayer presence 体系**：整体登记为服务
   端 fail-closed（同 LINK 分享）。若未来接入协作后端，需
   恢复 `s01.X`（view-only 全禁用仅放行 POINTER）、`dg9`
   自动切换、`l96` 远端光标渲染三件套。
4. `BrushTypes.ets` / `EditorViewModel.ets` 留位注释更新为
   指向本 ADR。

## 验证

- `d02-original-presence-zoom-tools-failclosed.mjs`：原版
  证据锚点 + Harmony absence/留位断言。
- 全量 Replay、双 HAP 构建随本阶段通过。
