# ADR-0615 原版页面管理面板多选模式

- 状态：Accepted
- 日期：2026-09-23
- 关联 Phase：648
- 接续：ADR-0612（面板本体）、ADR-0614（cell 上下文菜单）
- 证据：`docs/migration/evidence/original-page-multiselect-jadx-2026-09-23.md`

## 背景

原版 content manager 的 `qd2.UiState` 携带 `isSelecting` 与
`selectedPageIds` 两个独立信号：`fd2` case0 仅切换页键在选中集
的成员资格，`de2.l()`/n9j function9 case1 置 `isSelecting`，
`de2.u()` 一次复位 isSelecting/selectedPageIds/isSearchActive。
选择态下 cell tap 变为成员切换（`id2`），`tfh` 工具条提供
Select all/Deselect all 与批量 Copy/Duplicate/Delete/Cut/Paste/
Bookmark/Clear（`tc2` 7-case 分发，参数 `au1.T1(f)`）。
页剪贴板 `dg2` 本就是多页有序记录（ops+pageCount）。

## 决定

1. `PageOverviewPanel` 新增 `selecting`/`selectedPageIds` 状态：
   - cell 菜单末项 "Select"（`pages_menu_select`）→
     `toggleSelectPage`（fd2 case0 成员切换）；
   - 选中集非空 → `selecting=true`；选择态下 cell tap=成员切换，
     缩略图左上渲染勾选圈（选中=accent 实心 ✓）；
   - `pages` Prop 变更时剔除已消失页键（`onPagesChange`）。
2. 选择工具条（横向滚动 chip 行）：Select all/Deselect all 单钮
   切换（`allVisibleSelected()` 判定），批量 Copy/Duplicate/
   Delete/Cut/Paste?/Bookmark/Clear? + Done。
   - Select all = 当前过滤结果全集（`visibleItems()`，对齐 n9j
     case2 的 `qd2.c()`）；
   - Deselect all / Done = `exitSelection()`（de2.u() 三字段复位：
     退出选择态、清空选中集、关闭搜索行）。
3. `NotePage.dispatchPageSelectionAction(action, pageIds)`：
   `runPageOperation` 门禁下按选中页键批量执行参数化页操作。
   - Copy/Cut：`capturePageCopyPayload` 逐页构造（当前页画布
     capture、非当前页 `persistedPageCopyPlan` 持久层重建），
     `storeCopiedPages` 一次装载有序列表；
   - Cut = Copy + Delete（de2.p = o+q 语义）；
   - Delete/Duplicate 按**降序索引**循环，避免位移击穿未处理项；
   - Bookmark 逐页 `togglePageBookmarkAt`（PAGE_BOOKMARK 通道）；
   - Paste 锚定选中集末页（`indices.last()`）。
4. `OriginalPageClipboard` 升级为 `copiedPages: CopiedPagePayload[]`
   （对齐 dg2 多页记录）；`pasteCopiedPageAt` 逐 payload 顺次插入
   运行锚点之后，保持剪贴板页序。

## 与原版差异（fail-closed / 登记后续）

| 原版 | Harmony | 处置 |
|---|---|---|
| ~~批量 Clear 作用于任意选中集（de2.n 经 ae2 v1）~~ | ~~仅当前页可执行~~ → **Phase 649 关闭**：`clearOriginalPageContent` 持久层删除管线支持任意页 | 已关闭（ADR-0616） |
| ~~批量 op 经 ae2 单批应用 → 一步撤销~~ | ~~逐页循环 → 每页一条撤销~~ → **Phase 651 关闭**：PAGE_BATCH 批窗口共享 actionTime，peekGroup 跨页归并 | 已关闭（ADR-0618） |
| tfh 图标位 + 溢出菜单形态 | 横向滚动 chip 行 | ArkUI 形态差异，操作集合等价 |
| isSelecting 与选中集独立信号 | `selecting` 由选中集非空推导 + Done 显式退出 | 观测等价（原版选中集非空即渲染工具条） |
| 批粘贴锚点（e2 v16 内部位序不可静态判定） | 选中集末页之后 | 登记 |

## 验证

- 专项 Replay：`d05-original-page-multiselect.mjs` 31/31。
- 全量 Desktop Replay：533/533。
- `note@default` 与 `note@ohosTest` 双 HAP 构建 0 错误。
