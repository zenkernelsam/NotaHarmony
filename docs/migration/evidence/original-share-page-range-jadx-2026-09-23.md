# 原版分享面板页范围选择 — jadx 证据（2026-09-23）

阶段：Phase 644。结论：原版分享面板 `v6d` 持有页选择集合 `Set l` 与
总页数 `int m`，`b7d` 据此区分全量/部分页导出；Harmony 落地其
「全部页面 / 当前页」二选子集（任意子集依赖缩略图栅格面，登记差异
ADR-0611）。

## 原版证据（decompiled_1.0.3）

### 页选择集合

`defpackage/v6d.java:24`：`public final Set l`（页选择集合）；
`v6d.java:25` 区域：`public final int m`（总页数）。面板 VM 携带
完整的页勾选状态。

### 部分页导出判定

`defpackage/b7d.java:124-126`：`set = v6dVar2.l; if (set != null &&
set.size() != v6dVar2.m) { ... }` —— 导出流程按选择集合与总页数的
比较走部分页分支，上游 JPG/PNG/PDF 均支持子集导出。

## Harmony 实现（本 Phase）

- `EditorToolbar`：新增 `@State shareAllPages`（默认 true，对齐上游
  默认全选语义）；分享面板标题下加页范围切换
  `share_range_all`/`share_range_current`（双语字符串），选中态走
  `accent`/`control` 令牌；作用于 PDF/JPG/PNG 行，NOTE 恒整册、
  LINK 置灰不参与。
- JPG/PNG：`sharePagesAsImages(format, allPages)` —— 单页仍走
  `exportPageImage` 直存；整册逐页 `renderPageExport` + `packToData`
  后由 `PageImageExporter.exportPageImagesZip` 打进单个
  `${title}_pages_*.zip`（`page_001.<ext>` STORE 序，ZipWriter 复用）。
  选择 zip 单文件是因为 DocumentViewPicker.save 只回一个 URI，
  无法对齐上游多 URI Intent 分发（登记差异）。
- PDF：`shareNoteAsPdf(allPages)` —— 页列表解析为
  `allPages ? pages.slice() : [pages[currentPageIndex]]`，
  当前页得到合法单页 PDF。

## 登记差异（ADR-0611）

1. 任意子集勾选需缩略图栅格面，未实现；当前仅全量/当前页二选。
2. 整册 JPG/PNG 走 zip 单文件，非上游多文件 Intent 分发。
3. LINK 行仍 fail-closed（账号后端）。
