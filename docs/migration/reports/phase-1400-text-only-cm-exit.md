# Phase 1400 — text-only：OpenedContentManager 自动退出腿收官

- ADR：`docs/migration/adr/ADR-1336-text-only-cm-exit.md`
- 证据：`docs/migration/evidence/phase-1400-text-only-cm-exit.md`
- Replay：`docs/migration/replays/d02-original-text-only-cm-exit.mjs`（10 项）

## 背景

Phase 1395 落了 text-only 视图模式时，`q4i` 七项退出原因中
`OpenedContentManager` 登记为"无对应路径"——当时按"Harmony 尚未有
对应入口"处理。实则 Harmony 已有 content-manager 页面面板
（`PageOverviewPanel`/`showPageOverview`），对应路径存在但缺接线。
本 Phase 补齐该腿，`q4i` 的可移植原因全数落地。

## 原版证据

- `q4i.java` 枚举含 `OpenedContentManager("Opened Content Manager")`
  （fake field：发射点在字节码存在但未还原）。
- `c5i.b(reason)` 统一出口（Phase 1395 已对齐 `exitTextOnly`）。
- 其余登记：`InsertedSticky`（Harmony 无便签元素）、`LegacyDaemon`
  （daemon 内部）维持不适用。

## Harmony 实现

`onTogglePagesPanel` 打开腿（`!showPageOverview` → true）且
`textOnlyActive` 时先补发 `textOnlyExitSignal++`，再照常翻转面板——
退出是结果通知，不拦截打开。信号落统一出口：持久化
`is_text_only=false` + `text_only_auto_exit` toast（非 ManualExit）+
on/off 横幅收尾。关闭腿不发信号。

## 验证

- 新增 10 项断言全绿；`d02-original-text-only-mode.mjs` 更正注释 +
  2 项新断言（49→51）。
- `note@default` / clean `note@ohosTest` BUILD SUCCESSFUL；
  全量 Desktop Replay 基线绿。
