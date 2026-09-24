# Phase 677 报告：原版 POINTER（presence 光标）/ ZOOM / view-only —— fail-closed 登记

## 摘要

完成 `a6f` 13 工具枚举与 Harmony 的全面对账：PEN/PENCIL/
HIGHLIGHTER/TEXT/ERASER/SELECT/MEDIA/RECORD/LASER/REVIEW(tape)
十项已移植；剩余 POINTER(8)、ZOOM(12)、RULER(11) 三项均非
Harmony 缺失，而是原版自身门控/服务端域：

- **RULER**：`s01.a0` 无条件过滤 —— 原版即隐藏（ADR-0642）。
- **ZOOM**：`ac4.e0`(ZOOM_VIEW) 远程旗标 —— 1.0.3 未开。
- **POINTER**：多人 presence 光标 —— 广播 `zda` 位置经
  `aea`/`gm`/`mzc` 协作协议给会话参与者，`l96` 渲染远端
  presence_pen/highlighter/cursor 图标；`ac4.c0`
  (MULTIPLAYER_PRESENCE) 门控会话层；view-only 模式下
  `s01.X` 使其成为唯一放行工具、`dg9` 自动切换、`s01.b0`
  从列表剔除其余 —— 整体属协作服务端域。

## 判定

POINTER 在无协作后端时无任何可见输出（远端列表为空、无本地
渲染消费者）；渲染死按钮比缺位更偏离原版。三项继续留空
（次托盘 index 0/2/4），与原版门控后表面一致。
view-only/multiplayer presence 整体登记服务端 fail-closed，
若未来接入协作后端需恢复 `s01.X`/`dg9`/`l96` 三件套。

## 改动

- `note/src/main/ets/core/model/BrushTypes.ets`：枚举注释登记
  三个不移植成员及原因（ADR-0644/0642）。
- `note/src/main/ets/ui/editor/EditorViewModel.ets`：次托盘
  留位注释更新指向 ADR。
- `docs/migration/evidence/phase-677-original-pointer-zoom-presence-failclosed.md`。
- `docs/migration/adr/ADR-0644-original-pointer-zoom-presence-failclosed.md`。
- `docs/migration/replays/d02-original-presence-zoom-tools-failclosed.mjs`（33 断言）。

## 验证

- 专项 fixture：33/33。
- 全量 Desktop Replay：561/561，FAIL=0。
- `note@ohosTest` clean + `note@default` HAP 构建成功。
- 无模拟器/真机/Hypium 验证。

## 工具表对账终态

| a6f | 工具 | Harmony 状态 |
|-----|------|--------------|
| 0 | PEN | ToolType.PEN |
| 1 | PENCIL | ToolType.PENCIL |
| 2 | HIGHLIGHTER | ToolType.HIGHLIGHTER |
| 3 | TEXT | ToolType.DEFAULT |
| 4 | ERASER | WHOLE/PARTIAL_ERASER |
| 5 | SELECT | ToolType.SELECTION |
| 6 | MEDIA | 插入媒体入口 |
| 7 | RECORD | 录音工具 |
| 8 | POINTER | fail-closed（presence 协作域） |
| 9 | LASER | ToolType.LASER |
| 10 | REVIEW | ToolType.REVIEW（tape） |
| 11 | RULER | 原版 s01.a0 隐藏 |
| 12 | ZOOM | fail-closed（ZOOM_VIEW 旗标） |
