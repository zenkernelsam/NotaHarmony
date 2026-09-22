# Phase 620 — 交互标记后 200ms 长按菜单抑制（yqa/g39.b()）

## 原版证据

- `g39.java:17-31`：`a()` 打点（d=now）、`b()` 判定
  "距上次打点 <200ms"、`c()` 发射选区拖拽事件。
- `g1f.java` 打点来源：`ktc` 选区事件 null/空 → `Q.a()`
  （case4）；`r5f` 手势面事件 → `Q.a()`（default 每次打点）。
- `yqa.java:215-223`：`z=false` 分支 `if (g39.b()) return`——
  清空选区/切换工具后 200ms 内长按不弹粘贴菜单。
- `ej9.java:248-254`：`wtc` 拖拽结束通知受同一窗口抑制
  （Harmony 无 l51 总线，不可表达，记入边界）。

## 排查结论

Harmony `bindContextMenu(ClipboardPasteContextMenu, LongPress)`
无任何抑制——清空选区或切换工具后立即长按，粘贴菜单照常弹出。

## 修复

- 标记：`clearSelectionWithRegisterReset` + 页面加载 deselect +
  过小区域选区丢弃 deselect 三处写 `lastSelectionClearTime`；
  `applyActiveState` 中 `currentTool` 真正变化时写
  `toolChangedAt`。
- 门：`recentInteractionGateActive()` = 两标记较大者距今
  <200ms；`ClipboardPasteContextMenu` 门内不产出 `MenuItem`
  （bindContextMenu 无 veto，空 Menu 不弹层）。

## 验证

- 新增 replay `d02-original-recent-interaction-menu-gate.mjs`：14/14 绿。
- 全量 desktop replay 套件：510/510 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误（修复过程中出现的
  @Builder 位置错误已就地修正）。
- 未启动模拟器/真机/Hypium。

## 提交

Phase 620 commit（见 git log）。
