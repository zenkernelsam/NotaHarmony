# ADR-0517 — 原版新建笔记快捷动作

状态：Accepted（Phase 545）

## 背景

原版库内新建卡片 FAB（`ksh.g`/`t6j.b`）展开 `mw3` 快捷动作：
Record audio、Import file、Scan（能力门）、Capture（可空）。
Harmony 仅有单一 "+" FAB 直接建空白笔记。

## 决策

1. FAB 改 speed-dial：tap 展开 [New note / Record audio /
   Import file]；首项承载原卡片本体的空白创建语义，其余按
   mw3 顺序（scan/capture 登记不移植）。
2. Record audio → `createAndLaunch(true)` → 路由参数
   `autoRecord=1` → `NotePage` 加载成功后开录音面板并
   `startRecording()`（沿用源选择交互）。
3. Import file → 既有 `NoteImporter.importFromFile` → 刷新列表
   并打开导入笔记。
4. `ImportResult.CANCELLED` 区分 picker 取消（静默）与真实失败；
   `BackupPage` 同步静默处理（修复取消误报为"导入失败"）。

## 验证

`d02-original-new-note-quick-actions.mjs` 24/24；
`d02-library-note-create-delete-lifecycle-bound` 锚点演进至
`createAndLaunch`/`importAndOpen`（守卫不变）；全套 440/440；
`note@default` + `note@ohosTest` BUILD SUCCESSFUL。
