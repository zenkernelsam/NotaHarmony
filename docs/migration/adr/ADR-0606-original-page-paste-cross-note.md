# ADR-0606：原版页粘贴跨笔记资产链接（Cross-Note Page Paste）

- 状态：Accepted（取代 ADR-0603 决策 6 的 fail-closed 闸门）
- 日期：2026-09-23
- 阶段：Phase 639
- 证据：`docs/migration/evidence/original-page-paste-cross-note-jadx-2026-09-23.md`

## 背景

Phase 636 落地页级 Cut/Copy/Paste 时，按"图片资产行按笔记链接、跨笔记
写页需补资产链接"的推断，在 `NotePage.pasteCopiedPage` 与
`canPasteCopiedPage` 加了 fail-closed 闸门：仅无图片页允许跨笔记粘贴，
含图页 toast `paste_page_unsupported` 拒绝。

Phase 639 复核资产链路后发现该闸门过度保守：

1. **原版语义**：`mg2.b = dg2`（`CopiedPagesData { ops, pageCount }`）是
   进程级 op 流记录，字段里没有任何笔记绑定；Paste 把 op 流应用到当前
   打开的笔记文档，天然支持跨笔记。
2. **图片元素**：`commitOriginalDuplicatePageContent` →
   `transcodeOriginalPageElements` 对 IMAGE 叶发
   `encodeOriginalLocalCreateImageBlock`（完整资产元数据）→
   `OriginalCreateBlockOperationApplier.applyPayload` →
   `mergeImageAssetReference`：对既有资产行执行
   `mergeNoteIds(row.noteIds, [noteId])` 并保留 `local_path`——目标笔记
   的链接写入本就在 applier 内部。
3. **PDF 背景**：`insertCopiedPage` → `persistOriginalDuplicatePage` 的
   CreatePage 负载携带完整 nz9（含 `pdf.metadata`）→
   `OriginalCreatePageOperationApplier.mergePdfAsset` →
   `mergeOriginalAssetReference`，同样把文档资产 `note_ids` 合入目标
   笔记。
4. **资产字节**：`filesRoot/assets/final/<sha512>` 全局内容寻址存储，
   不随笔记分桶；`resolveImageAsset`/`resolveOriginalAsset` 按哈希全局
   查找，目标笔记读到的是同一字节文件。
5. **计划校验**：`validateOriginalDuplicatePageContentPlan` 只校验身份
   格式与可编码性，无笔记域假设；`readOriginalClipboardSourceZIndex`
   对外源元素 id 在目标笔记内查无此行返回 `undefined`，空目标页
   `maximumZIndex === null` 时守卫放行。

## 决策

移除 `pasteCopiedPage` 的跨笔记含图 fail-closed 分支与
`canPasteCopiedPage` 的 `payload.noteId === this.noteId ||
images.length === 0` 限制；Paste 菜单项回到原版的单一门控
（剪贴板非空），同时删除只为该闸门存在的 `paste_page_unsupported`
字符串资源（base + zh_CN）。

保留的既有边界不变：目标笔记必须 original-aligned
（`insertCopiedPage` → `persistOriginalDuplicatePage` 内部校验），
否则 fail-closed 抛错——与 Phase 636 一致。

## 后果

- 含图片、含 PDF 背景页均可跨笔记粘贴，撤销/重做语义不变
  （DUPLICATE_PAGE 伴随 op 不触及资产行）。
- `CopiedPagePayload.noteId` 字段保留为来源溯源信息，不再作为门控。
- ADR-0603 决策 6 被本 ADR 取代。
