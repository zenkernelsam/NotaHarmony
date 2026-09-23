# ADR-0614 原版页面管理面板 cell 上下文菜单

- 状态：Accepted
- 日期：2026-09-23
- 关联 Phase：647
- 接续：ADR-0612（面板本体）、ADR-0613（页内搜索）
- 证据：`docs/migration/evidence/original-page-context-menu-jadx-2026-09-23.md`

## 背景

原版页总览 cell 提供下拉菜单（`n9j`），项序为 Add page、Cut、
Copy、Paste?、Duplicate、Rotate Page?、Create Template（flag）、
Clear Page、Delete；点击经 `fd2` 按页键分发到 `de2`/`zd2`/`e2`
页操作，**不改 `qd2.currentPageIndex`**（面板内操作不导航）。

## 决定

1. `PageOverviewCell` 增加 `bindContextMenu`（LongPress）渲染同一
   序的 MenuItem；`onPageAction(pageIndex, action)` 回调上抛宿主。
   - Paste 门禁 `canPastePages`（对齐 `mg2.b != null`）；
   - Rotate 门禁 `rotatedOriginalPageInfo(page) != null`（对齐 z3）；
   - Create Template 上游 flag 关闭，继续缺席；
   - Clear 仅当前页显示（见差异表）。
2. `NotePage.dispatchPageContextAction`：`runPageOperation` 门禁下
   分发到参数化页操作；既有 `*CurrentPage` 方法全部改为委托
   `…At(this.currentPageIndex)`，行为不变。
3. 非当前页内容快照：`persistedPageSnapshot` /
   `persistedPageCopyPlan` 用 `StrokePersistence.loadElements`
   （`page_element_snapshot`）重建 `PageContentSnapshot`/`PageCopyPlan`
   （含 `originalGroupGraphForPageCopy` 组子图），替代画布
   `captureCurrentPage*`。
4. 选中态语义：删除/旋转非当前页不移动 `currentPageIndex`
   （`selectedBefore/After` 保持当前页 id；旋转不重选），对齐原版
   「面板操作不导航」。

## 与原版差异（fail-closed / 登记后续）

| 原版 | Harmony | 处置 |
|---|---|---|
| cell ⋯ 下拉菜单（`apb.d`） | 长按 `bindContextMenu` | ArkUI 形态差异，项序等价 |
| Clear Page 对任意页可用 | 仅当前页（画布信号管线） | 非当前页清空需独立 op/撤销通道，登记后续 |
| fd2 case0 缩略图多选 | 未实现 | 沿用 ADR-0612 多选登记 |
| 面板内 Add/Duplicate/Paste 不动 currentPageIndex | Harmony 沿用既有语义导航到新建页 | 登记差异 |
| fd2 的 zd2 v0/v1 映射 | 由既有注释锚定（v0=Add/u5j.i，v1=Rotate） | `zd2.invokeSuspend` 未反编译，映射依据已有注释与菜单序交叉确认 |

## 验证

- `d05-original-page-context-menu.mjs`：20 断言全绿。
- 全量 Desktop Replay：532/532。
- `note@ohosTest` / `note@default` clean 构建成功，无新增 ArkTS
  错误。
- 未运行模拟器/真机/Hypium。
