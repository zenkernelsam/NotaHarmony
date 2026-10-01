# Phase 1400 证据 — text-only OpenedContentManager 自动退出腿

## 原版证据（decompiled_1.4.2）

- `defpackage/q4i.java`：text-only 退出原因枚举完整列出 7 项——
  `ImportedFile`/`InsertedImage`/`InsertedSticky`/`LegacyDaemon`/`ManualExit`/
  `OpenedContentManager`/`SwitchedTools`。
- `OpenedContentManager` 的发射点被 JADX 还原为 fake field
  （枚举由 values 数组重建；发射语句存在于字节码但未落入可见反编译体）。
  枚举成员本身是硬证据：**打开内容管理器是 text-only 的退出触发之一**。
- 统一出口 `c5i.b(q4i reason)`（Phase 1395 已对齐）。
- `k59`/内容管理器：原版 CM 打开后 text-only 退出，面板仍照常打开
  （exit 是结果通知，不拦截打开动作）。

## Phase 1395 登记 → 本 Phase 收官

Phase 1395（ADR-1331）把三条原因登记为"无对应路径"：

| 原因 | 状态 |
|------|------|
| `OpenedContentManager` | **本 Phase 接入**——Harmony 已有 `PageOverviewPanel`/`showPageOverview`，`onTogglePagesPanel` 打开腿（false→true）且 `textOnlyActive` 时补发 `textOnlyExitSignal` |
| `InsertedSticky` | 维持不适用——Harmony 无便签元素类型 |
| `LegacyDaemon` | 维持不适用——原版 daemon 内部原因，无对应入口 |

## Harmony 实现映射

| 原版 | Harmony |
|------|---------|
| `q4i.OpenedContentManager` → `c5i.b` | `onTogglePagesPanel` 打开腿 → `textOnlyExitSignal++` → `onTextOnlyExitSignalChange` → `exitTextOnly('PageAction')` |
| 退出 + 面板照常打开 | 信号先行、`showPageOverview` 翻转不被拦截 |
| 非 ManualExit → "Showing the full note" snackbar | `setTextOnly(false, reason)` 非 ManualExit 弹 `text_only_auto_exit` toast（已具备） |

## 边界

- 只拦"打开"腿（`!showPageOverview`）；关闭腿（true→false）不发信号。
- `bindSheet` 下滑关闭路径（`onDismiss`→`showPageOverview=false`）不触发——
  原版原因语义即"打开"。
