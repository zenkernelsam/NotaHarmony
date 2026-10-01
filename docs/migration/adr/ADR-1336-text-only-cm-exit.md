# ADR-1336 — text-only：OpenedContentManager 自动退出腿

- 状态：已接受
- 日期：2026-08（Phase 1400）
- 证据：`docs/migration/evidence/phase-1400-text-only-cm-exit.md`
- 前置：ADR-1331（text-only 模式本体）
- Replay：`docs/migration/replays/d02-original-text-only-cm-exit.mjs`

## 决策

把 `q4i.OpenedContentManager` 退出腿接上：`onTogglePagesPanel` 打开
content-manager 页面面板（false→true）且 text-only 激活时补发
`textOnlyExitSignal`——与 `ImportedFile` 同一条页面侧信号通道，落到
统一出口 `exitTextOnly`→`setTextOnly(false, reason)`（持久化
`is_text_only=false` + "Showing the full note" toast + 横幅收尾）。

## 理由

- `q4i` 枚举成员即契约硬证据（JADX fake field：发射点在字节码中存在
  但未还原到可读体）；Phase 1395 登记"无对应路径"是因为当时
  Harmony 尚无 content-manager 面板——现有 `PageOverviewPanel`，
  对应路径成立。
- 语义忠实：退出是结果通知，不拦截面板打开（信号先发、翻转照常）。
- 只拦打开腿；关闭/下滑收起不触发。

## 行为差异

无新增差异。`InsertedSticky`（Harmony 无便签元素）/`LegacyDaemon`
（daemon 内部原因）维持不适用登记。

## 回归

- 新增 `d02-original-text-only-cm-exit.mjs`（10 项断言）。
- `d02-original-text-only-mode.mjs` 注释更正 + 2 项新断言（49→51）。
- `note@default` / clean `note@ohosTest` 绿，全量 Replay 基线绿。
