# 原版页面管理面板 cell 上下文菜单证据 — JADX 静态提取

日期：2026-09-23 · 来源：`decompiled_1.0.3` · 仅静态证据。

## 1. 菜单构成（`n9j.java` ~1955–2100）

cell 下拉菜单按序渲染（条件项括注）：

1. **Add page** `content_manager_add_page` + `add_page` 图标（仅真实页 cell，z4）
2. **Cut** `content_manager_cut` + `cut` 图标（z4）
3. **Copy** `content_manager_copy` + `copy` 图标（恒显）
4. **Paste** `content_manager_paste` + `paste_content_manager` 图标
   （z4 && z=剪贴板非空 `mg2.b != null`）
5. **Duplicate** `content_manager_duplicate` + `duplicate` 图标（z4）
6. **Rotate Page** `content_manager_rotate_page` + `rotate_page` 图标
   （z4 && z3=可旋转）
7. **Create Template** `content_manager_create_template` +
   `create_template` 图标——`lc4.a(ac4.w0)`（INTERNAL_USERS_ONLY，
   生产 1.0.3 关闭）
8. **Clear Page** `content_manager_clear_page` + `clear_page` 图标（z4）
9. 分隔线（`apb.e(kgh.e, …, kgh.f)`）后接 **Delete**
   `content_manager_delete`

## 2. 分发（`fd2.java`）

cell 菜单项点击按 case 分发（`de2` = 页 VM，`pd2.a` = 页键 `cxc`）：

| case | 动作 | 目标 |
|---|---|---|
| 0 | 选中开关 | `qd2.f` ± `tz9(cxc)`（mask 479 只写 selectedPageIds） |
| 1 | Clear Page | `de2.n([key])` → `ae2` v1 |
| 2 | Delete | `de2.q([key])` → `ae2` v4 |
| 3 | Add Page | `zd2(de2,cxc,…,0)` → `u5j.i` 在该页后插页 |
| 4 | Cut | `de2.p([key])` → `ae2` v3（copy+delete） |
| 5 | Copy | `de2.o([key])` → `ae2` v2 |
| 6 | Paste | `e2(16)` → `mg2.b` 剪贴板落页 |
| 7 | Duplicate | `de2.r([key])` → `ae2` v5 |
| default | Rotate Page | `zd2(de2,cxc,…,1)` |

要点：**全部按页键作用，不改 `qd2.currentPageIndex`**——面板内
操作不导航。

## 3. Harmony 对齐点（Phase 647）

- `PageOverviewCell` 长按 `bindContextMenu` 渲染同一序的 MenuItem；
  Paste 受 `canPastePages` 门禁（`copiedPagePayload() != null`），
  Rotate 受 `rotatedOriginalPageInfo(page) != null` 门禁，
  Clear 仅当前页展示（画布信号管线，fail-closed），
  Create Template 上游 flag 关闭故缺席。
- `NotePage.dispatchPageContextAction(pageIndex, action)` →
  `runPageOperation` 门禁下分发到参数化页操作：
  `addPageAt`/`cutPageAt`/`copyPageAt`/`pasteCopiedPageAt`/
  `duplicatePageAt`/`rotatePageAt`/`deletePageAt`；既有
  `*CurrentPage` 入口全部委托 `…At(currentPageIndex)`。
- 非当前页快照经 `persistedPageSnapshot`/`persistedPageCopyPlan`
  从 `page_element_snapshot` 重建（`loadElements` 同形）；
  非当前页删除不改选中态（`selectedBefore/After` = 当前页 id），
  非当前页旋转不导航。

## 4. 差异登记

- 触发手势：原版为 cell ⋯/下拉（`apb.d`）；Harmony 用
  `bindContextMenu` 长按（ArkUI 习惯），功能等价。
- Clear Page 对非当前页缺席（Harmony 清空管线绑定当前页画布；
  持久层整页清空需独立 op/撤销通道，登记后续）。
- Add/Duplicate/Paste 成功后 Harmony 导航到新建页（沿用既有
  `*CurrentPage` 语义）；原版面板操作不动 currentPageIndex。
- fd2 case0（缩略图多选开关）属多选表面，登记 ADR-0612/后续。
