# Phase 636 — 原版页级剪切/拷贝/粘贴（Page Cut / Copy / Paste）

- 日期：2026-09-23
- 证据：`docs/migration/evidence/original-page-cut-copy-paste-jadx-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0603-original-page-cut-copy-paste.md`
- Replay：`docs/migration/replays/d04-original-page-copy-cut-paste.mjs`（48 断言）

## 原版行为

`n9j` 单页菜单顺序：Add Page、Cut、Copy、Paste（仅剪贴板非空）、
Duplicate、Rotate Page、Create Template（内部旗标）、Clear Page。

- **Copy**（`de2.o` → `ae2` 变体 2）：`u5j.e` 把页负载（有效 nz9 +
  `l7j.c` 单页 PDF 折叠 + `oz9` bookmark）序列化后存入进程级页剪贴板
  `mg2.b = dg2`（`CopiedPagesData { ops, pageCount }`）。
- **Cut**（`de2.p` → `ae2` 变体 3）：同 Copy 写剪贴板，随后经
  `de2.i` 构造删除 ops 并应用——日志形状与 Delete Pages 相同。
- **Paste**（`mg2.b != null` 门控）：经 `lg2`/`m1d.c0` 在锚点转码
  重放，与 Duplicate 产出同型 op 流（CreatePage + 实体创建、全新身份）。

## Harmony 实现

- `rendering/OriginalPageClipboard.ets`（新）：进程级页剪贴板
  `copiedPage` 单例 + `CopiedPagePayload`（有效 nz9 背景、bookmark、
  `PageCopyPlan`）。内存态，与 `mg2` 一致。
- `UndoRedoManager.ets`：`PageCopyPlan`（PageContentSnapshot + 组子图）
  + 桥接 `captureCurrentPageCopyPlan` / `commitCopiedPageContent`。
- `NoteCanvasView.ets`：抽取 `currentPageCopyPlan`（Duplicate 与 Copy
  同源）；`pageCopyPlanToPastePlan` 在持久化边界显式重包
  （arkts-no-structural-typing 禁接口间结构赋值）。
- `PageRepositoryImpl.ets`：抽取 `insertPageAfterAnchor` 共享体；
  新增 `insertCopiedPage`——锚点后 CreatePage 携带剪贴板背景/书签，
  同一 `DUPLICATE_PAGE` 伴随 op（原版两手势同型日志，语义一致）。
- `NotePage.ets`：`copyCurrentPage`（flush → 计划 → 负载入剪贴板）、
  `cutCurrentPage`（copy + 既有 deleteCurrentPage，即 DELETE_PAGE
  行动）、`pasteCopiedPage`（锚点=当前页，insertCopiedPage +
  commitCopiedPageContent + push DUPLICATE_PAGE 行动）；
  `pageClipboardVersion` 驱动 Paste 菜单可见性。
- `PageManagerBar.ets`：菜单按原版顺序加 Cut、Copy，Paste 仅在
  `canPastePage` 时插入 Copy 与 Duplicate 之间。
- 资源：`cut_page`/`copy_page`/`paste_page`/`paste_page_unsupported`
  （base + zh_CN）。

## 已知差异（fail-closed，见 ADR-0603）

- 剪贴板存物化负载（背景+元素计划）而非 op 流；转码重放语义一致。
- ~~含图片页暂不支持跨笔记粘贴（资产行按笔记链接）；无图片页可跨笔记。~~
  Phase 639 复核：链接写入本就在 CREATE_BLOCK/CREATE_PAGE 应用器内，
  闸门已移除（ADR-0606）。

## 验证

- `d04-original-page-copy-cut-paste.mjs`：**48/48**。
- 全量 Desktop Replay：**522/522 PASS**。
- `note@ohosTest` / `note@default` HAP：静态构建成功（无新增 ArkTS 错误）。
- 未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
