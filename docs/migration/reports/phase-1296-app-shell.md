# Phase 1296 报告 — 应用壳

## 完成内容

- `NbApplication`(Application+fed=Hilt DI+`x30` 组件
  管理器+`igb`/`id7`/`g72` 注入器）；`MainActivity`(r12
  Compose 单 Activity+`uiState`）；`MissingNative
  LibraryActivity`（原生缺失 AlertDialog）；`AppUpgrade
  Receiver`（包升级 goAsync）；`initializers/*`(`g06`
  AndroidX Startup：AppStartup+Logging backend_override)
  —— 启动引导+DI+容错。

## 产出

- evidence `phase-1296-app-shell.md`
- fixture `d02-app-shell.mjs`（10/10）
- ADR-1240
