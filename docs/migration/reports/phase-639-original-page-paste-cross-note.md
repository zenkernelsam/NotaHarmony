# Phase 639 — 原版页粘贴跨笔记放开（资产链接已在应用器内）

- 日期：2026-09-23
- 证据：`docs/migration/evidence/original-page-paste-cross-note-jadx-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0606-original-page-paste-cross-note.md`
  （取代 ADR-0603 决策 6）
- Replay：`docs/migration/replays/d04-original-page-copy-cut-paste.mjs`
  （50 断言，更新跨笔记钉）

## 原版行为

`mg2.b = dg2`（`CopiedPagesData { ops, pageCount }`）是进程级 op 流记录，
字段无笔记绑定；Paste 把 op 流应用到当前打开笔记，跨笔记粘贴为原版
原生语义，唯一门控是剪贴板非空（`de2` 读 `mg2Var.b != null`）。

## Harmony 实现

Phase 636 曾推断"图片资产行按笔记链接、跨笔记需补写"，加了
fail-closed 闸门（含图页跨笔记 toast 拒绝 + `canPasteCopiedPage` 限流）。
本 Phase 复核确认链接写入本就内建于应用器：

- `OriginalCreateBlockOperationApplier.mergeImageAssetReference`：
  图片元素落地时把 `note_asset.note_ids` 合入目标笔记，保留
  `local_path`。
- `OriginalCreatePageOperationApplier.mergePdfAsset` →
  `mergeOriginalAssetReference`：CreatePage 负载携带的 PDF 背景
  `metadata` 同样合入。
- 资产字节存于全局内容寻址 `assets/final/<sha512>`，跨笔记可读。

改动：

- `NotePage.canPasteCopiedPage`：回到 `payload !== null &&
  pages.length > 0` 单一门控。
- `NotePage.pasteCopiedPage`：移除跨笔记含图 fail-closed 分支。
- 资源：删除 `paste_page_unsupported`（base + zh_CN，仅该闸门使用）。
- 注释：剪贴板与 NotePage 注释更新为资产合并语义。

## 登记边界（不变）

- 目标笔记须 original-aligned（`persistOriginalDuplicatePage` 校验），
  否则 fail-closed——与 Phase 636 一致。
- `CopiedPagePayload.noteId` 保留为来源溯源，不作门控。

## 验证

- `d04-original-page-copy-cut-paste.mjs`：**50/50**（新增两条应用器
  链接钉 + 闸门移除钉）。
- 全量 Desktop Replay：**524/524 PASS**。
- `note@ohosTest` / `note@default` HAP：clean 静态构建成功
  （无新增 ArkTS 错误）。
- 未启动模拟器、虚拟机、真机或 Hypium；T-042 保持 Goal 最后任务。
