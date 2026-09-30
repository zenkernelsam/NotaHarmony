# Phase 1317 报告 — 应用入口 + Want 分流

## 完成内容

- `NoteAbility`（`UIAbility`：onCreate 入队 shared/launch
  /deepLink/openTarget **Want 分流队列** + `ThemeStore.
  init` + onNewWant 热启动 + onWindowStageCreate→主题
  恢复+降级→`loadContent('pages/Index')`）+ 4 Ability
  （主/备份/Form 卡片）+ `noteformeditability/`（Folder/
  NoteThumbnail 卡片编辑 ≈ widget 配置）—— 入口架构
  映射原版 MainActivity intent 处理。

## 产出

- evidence `phase-1317-app-entry.md`
- fixture `d02-app-entry.mjs`（10/10）
- ADR-1261
