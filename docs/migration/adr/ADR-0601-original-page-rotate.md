# ADR-0601 原版页面旋转：页级 ModifyPage 背景寄存器写入

- 状态：accepted；Phase 634；2026-09-23
- 上下文：原版内容管理器菜单 Rotate Page
  （`n9j` → `fd2` case 8 → `zd2` 变体 1）此前在 Harmony 页管理菜单
  完全缺席。指令级转储确认该动作是**页级** `ModifyPage` 写：
  ge8.field2（m2d setter→nz9），与 `updatePage` 原有的
  "original page settings must use note-level SET_METADATA" 拒绝路径冲突
  ——原版页级设置与笔记级设置是两条寄存器（
  `docs/migration/evidence/original-page-rotate-jadx-2026-09-23.md`）。

## 决策

1. `OriginalSetMetadataPayloadEncoder.ets` 导出
   `encodeOriginalPageBackgroundTableBlob`——nz9 内部引用全部相对，
   作为可重定位 blob 供 ge8.field2 嵌套复用（不改既有 l2d 编码路径）。
2. `OriginalModifyPagePayloadEncoder.ets` 新增
   `encodeOriginalModifyPageBackground(pages, background)`：
   ge8 root vtable `[4, 0, 12, 0]`（pages@4 / moveTo 缺席 /
   setter@12 / bookmark 缺席）；m2d setter field0→nz9 blob，
   null 背景保留 setter 但省略 field0（寄存器复位语义与原版一致）。
3. `OriginalPagePersistence.ets` 新增 `persistOriginalPageBackground`
   ——与 `persistOriginalPageBookmark` 同型：对齐校验 → 页身份解析 →
   ModifyPage op 编码/应用/journal（`ORIGINAL_MODIFY_PAGE`）。
4. `PageRepositoryImpl.updatePage`：original-aligned 页不再抛错，改走
   `persistOriginalPageBackground` + `appendStructureHistoryMutation`
   （UPDATE_PAGE 伴随 op 承载 before/after 物化页数组）——页级撤销
   复用既有 PAGE_SETTINGS 通道，重启后 `materializeAction` 经
   `changedPages` 还原同一动作类型。
5. `PageBackgroundModel` 新增 `nextOriginalPageRotation`
   （0→π/2→π→3π/2→0，非基数归 0，eps 1e-4 对齐 `cl4.a`/`ddg.g`）
   与 `rotatedOriginalPageInfo`（有效背景 `wz9.B()` 等价 + `l7j.c`
   PDF 单页消费重建 + 解码器同公式的物化维度）。
6. UI：`PageManagerBar` 页菜单在 Bookmark 与 Clear Page 之间挂
   Rotate Page（原版菜单位序 rotate 紧邻 duplicate/create_template，
   Harmony 精简菜单内保持相对次序）；`NotePage.rotateCurrentPage`
   走 `runPageOperation` + PAGE_SETTINGS 历史通道。

## 后果

- 单页旋转以 op 形式进入 operation_log，LWW 寄存器语义与原版一致；
  撤销/重做、持久历史物化零新增类型。
- 渲染侧无需改动：`PaperRenderer`/`PdfRasterPlan` 早已消费
  `rotationRadians` 基数角。
- fail-closed：无有效背景（null register+fallback）→ 早退；
  PDF cropBoxes 下标越界 → 抛错走既有 toast；非基数旋转值在
  `validatePageBackground`/`isCardinalRotation` 处拒绝。
- 已知边界：原版 zd2 变体 1 对 PDF 页重建 sw9 时 `pageOffset` 取
  `wz9.F()`（pageInAsset），Harmony 同取 `page.originalPageInAsset`；
  对 pagesConsumed>1 的复合消费页，旋转收敛为单页消费——与原版一致。
