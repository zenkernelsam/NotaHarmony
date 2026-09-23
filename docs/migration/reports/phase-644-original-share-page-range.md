# Phase 644 — 分享面板页范围选择（全部页面 / 当前页）

日期：2026-09-23。前置：Phase 641~643（分享面板 + 三类格式导出）。

## 原版行为（decompiled_1.0.3）

- `v6d.java`：面板 VM 持有 `Set l`（页选择集合）+ `int m`（总页数）。
- `b7d.java:126`：`set.size() != v6dVar2.m` 判定部分页导出 ——
  PDF/JPG/PNG 支持任选页子集。

## Harmony 改动

| 文件 | 改动 |
|------|------|
| `ui/editor/EditorToolbar.ets` | `@State shareAllPages` + 面板顶部页范围切换（accent/control 令牌选中态）；PDF/JPG/PNG 行派发携带范围 |
| `data/PageImageExporter.ets` | 新增 `exportPageImagesZip`：整册逐页栅格 → ZipWriter `page_001.<ext>` STORE → `.zip` picker 保存 |
| `ui/editor/NotePage.ets` | `shareCurrentPageAsImage` → `sharePagesAsImages(format, allPages)`（单页直存 / 整册 zip）；`shareNoteAsPdf(allPages)`（整册 / 单页 PDF）；`EXPORT_JPEG_QUALITY` 统一两处 q92 |
| 双语 string.json | `share_range_all` / `share_range_current` |

## 登记差异（ADR-0611）

1. 任意子集勾选需缩略图栅格面，未实现（仅全量/当前页）。
2. 整册图像走 zip 单文件（picker 单 URI 限制），非多文件 Intent。
3. LINK 行仍 fail-closed。

## 验证

- fixture `d05-original-share-page-range.mjs` 23 断言绿；三份 d05
  分享 fixture pin 更新后全绿。
- 全量 Desktop Replay 529/529。
- `note@ohosTest`、`note@default` clean 构建通过；无新增 ArkTS error。
