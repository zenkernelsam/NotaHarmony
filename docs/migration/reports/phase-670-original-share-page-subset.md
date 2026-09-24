# Phase 670 — 原版分享面板任意页子集选择迁移

日期：2026-09-24
前置：Phase 669（`da24f729`）

## 目标

将原版分享面板的页范围选择从 P644 的"全部页面/当前页"二选
升级为原版的任意页子集语义（`v6d.l` 页集合 + `r6d.
PAGE_SELECTION` 缩略图栅格屏 + `b7d.q` 页 toggle）。

## 原版行为（证据：b7d / v6d / r6d / strings）

- `v6d.l` = `Set<Integer>` 页索引集合，**null = 全部页**；
  `v6d.m` = 页总数；`v6d.n` = `r6d` 屏态（MAIN/PAGE_SELECTION/
  PASSWORD_ENTRY）。
- `b7d.q(i, z)`：null 集合先物化 `V(0,m)` 全量再 add/remove。
- `b7d.l(i, i2)`：缩略图预取窗口 → `X` → `v6d.o`。
- 主屏页范围行：`page_range` 标签 + `All`/`%1$d of %2$d` 值。
- `pj(format, j, i, isPartial)`：`isPartial = l!=null && size!=m`。
- `b7d(List noteIds)`：多笔记分享默认 PDF（本 Phase 登记）。

## Harmony 实现

- `EditorToolbar.ets`：`sharePageIndexes`（null=All）+
  `shareScreen`（main/pages）双状态；MAIN 屏页范围行 →
  `pages` 屏（返回/计数/全选/取消全选/Done + 4 列
  `SharePageCell` 勾选栅格）；`toggleSharePage` = b7d.q 等价；
  `bindSheet.onDisappear` 重置（每次打开全新会话）；分发签名
  改为 `pageIndexes:number[]|null`。
- `SharePageCell`：缩略图懒取 + PixelMap 自持/释放 + ✓/圈 +
  页码 + tap 切换（无上下文菜单——那是页概览面板的职责）。
- `NotePage.ets`：`resolveSharePages` 按页序过滤；
  `sharePagesAsImages`/`shareNoteAsPdf` 消费页集合（空→不导出）；
  `requestShareThumbnail` 懒建渲染器 + 串行链，
  `aboutToDisappear` 释放；`sharePages`/`onShareThumb` 注入工具栏。
- 字符串：`share_page_range`/`share_range_selected` 双语新增，
  `share_range_current` 移除。

## 适配差异（文档化）

1. 预取窗口 → cell 懒取 + 串行链（语义等价，规模适配）。
2. "当前页"快捷项移除（原版无此概念，栅格子集表达）。
3. 空子集不导出（原版行为不可判定，fail-closed 不导出）。
4. NOTE 行恒整册（原版同）。

## fail-closed 保留

- `r6d.PASSWORD_ENTRY`/PDF 导出密码、`v6d.i/j`（include_*
  开关）、多笔记分享、LINK 格式——登记后续。

## 验收

- `d05-original-share-page-subset.mjs`：25/25。
- `d05-original-share-page-range/-page-image/-pdf/-editor-share`
  针脚更新后全绿。
- 全量 Desktop Replay、clean + `note@ohosTest` + `note@default`
  构建全绿。

## 变更文件

- 修改：`note/src/main/ets/ui/editor/EditorToolbar.ets`、
  `note/src/main/ets/ui/editor/NotePage.ets`、
  `note/src/main/resources/base/element/string.json`、
  `note/src/main/resources/zh_CN/element/string.json`、
  `docs/migration/replays/d05-original-share-page-range.mjs`、
  `docs/migration/replays/d05-original-share-page-image.mjs`、
  `docs/migration/replays/d05-original-share-pdf.mjs`、
  `docs/migration/replays/d05-original-editor-share.mjs`、
  三份跟踪文档。
- 新增：`docs/migration/replays/d05-original-share-page-subset.mjs`、
  `docs/migration/evidence/phase-670-original-share-page-subset.md`、
  `docs/migration/adr/ADR-0637-original-share-page-subset.md`、本报告。
