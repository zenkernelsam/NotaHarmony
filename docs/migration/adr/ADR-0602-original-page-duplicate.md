# ADR-0602 原版页面复制（Duplicate Page）：锚定 CreatePage + 独立 DUPLICATE_PAGE 历史伴随

- 状态：accepted；Phase 635；2026-09-23
- 上下文：原版内容管理器菜单 Duplicate
  （`n9j` → `de2.r` → `ae2` 变体 5）此前在 Harmony 页管理菜单完全
  缺席。证据链确认原版复制是「`u5j.e` 页序列化 + `de2.j` 锚点 +
  `m1d.c0` 转码应用」的 op 流（
  `docs/migration/evidence/original-page-duplicate-jadx-2026-09-23.md`）。

## 决策

1. **页元数据**：`persistOriginalDuplicatePage` 发
   `ORIGINAL_CREATE_PAGE` op——`encodeOriginalLocalCreatePage` 以
   **源页身份为 `location` 锚点**（等价 `de2.j` 末选中页锚点），
   并携带 `duplicatedOriginalPageBackground` 产出的**完整有效 nz9**
   （`wz9.u` 语义：register ?? note 兜底；PDF 页经
   `collapsedOriginalPagePdf` = `l7j.c` 单页消费折叠）。ln2 field 3
   透传源页 `bookmarked`（`haj.a` 的 `oz9` 序列化等价）。
2. **实体内容**：复用剪贴板转码机制——抽出共享
   `transcodeOriginalPageElements`（mappedIds 全新身份、RichText
   INSERT_STRING+样式重放、底向上 CreateGroup），新增
   `commitOriginalDuplicatePageContent` 入口：
   `validateOriginalDuplicatePageContentPlan` 允许**空组图**
   （原版逐实体 op 流无合成包裹 Group），目标页必须为新空页。
3. **历史**：新增 `OpType.DUPLICATE_PAGE = 4`（占用枚举空位，
   既有持久值不动）+ `DuplicatePageOpCodec`（NDP1）。
   `duplicatePage` 在同一事务内追加一条伴随 op，携带
   fromRevision/toRevision/sourcePageId/pageId/pageOrderBefore/After；
   验证器钉死「副本紧随源页」。
   **不能复用 CREATE_PAGE 分类**：`classifyPageStructureMutation`
   把任何单页插入折叠为 CREATE_PAGE，而其物化器要求尾页插入——
   中间位置复制会被误判或拒绝。
4. **撤销/重做**：可见性语义——undo 经
   `persistOriginalPageVisibility(..., true)` 隐藏副本（实体行保留），
   redo 经 `restoreDuplicatedPage`（visibility false +
   CREATE_PAGE 型 REDO 移动 op）恢复。与原版对齐页删除的
   可见性写路径同型；不建 checkpoint（内容从未被移除）。
   重启物化只认 PUSH op；UNDO/REDO 移动 op 不参与物化，
   故 REDO 移动 op 的 CREATE_PAGE 类型不会被误读为尾页插入。
5. **组图复制**：`originalGroupGraphForPageCopy` 先以不动点收敛
   **页内组集**（成员全在 copiedLeafIds ∪ pageLocal 内），再只对
   页内根走 `copyOriginalGroupGraph`——selectionGroups 是笔记级，
   异页组不再误伤复制；引用本页却不完整页内的组属损坏，
   fail-closed 返回 null。
6. **UI**：`PageManagerBar` 菜单按原版位序在 Bookmark 与
   Rotate Page 之间挂 Duplicate（`n9j` 菜单 duplicate 紧邻
   rotate）；`NotePage.duplicateCurrentPage` 走
   `runPageOperation`：flush → `captureCurrentPage` →
   `duplicatePage` → `commitDuplicatePageContent` → 选中副本 →
   `pushPageAction`。空页复制跳过内容写（页级 op 已足够）。

## 后果

- 复制页以原版 CreatePage + 逐实体 create op 进入 operation_log，
  全新页身份/元素身份与原版 `m1d.c0` 重发语义一致；可同步。
- 持久历史物化：`DUPLICATE_PAGE` 伴随 op → `DuplicatePageAction`
  （恰好一条 op；内容转码 op 不带历史元数据，不进伴随组）。
- fail-closed：非对齐笔记/源页缺失 → 抛错；目标页非空 → 抛错；
  组图损坏 → 抛错；插入位置校验 `after[sourceIndex+1]` 钉死。
- 已知边界：Harmony 复制仅当前页（UI 单页上下文），原版
  `de2.r` 接受多选页列表——多页批量复制属内容管理器多选
  epic，不在本 Phase。
- `create_template` 菜单项为 `lc4.a(ac4.w0)` INTERNAL_USERS_ONLY
  门控，生产 1.0.3 不可见——Harmony 不挂该项即 parity（已核实）。
