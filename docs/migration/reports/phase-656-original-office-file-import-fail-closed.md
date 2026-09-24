# Phase 656：Office/RTF/Apple 文档导入 fail-closed（jv5 fca.f 转换漏斗）

日期：2026-09-24
接续：Phase 655（独立音频文件导入）
ADR：ADR-0623
证据：`docs/migration/evidence/original-office-file-import-jadx-2026-09-24.md`
专项 Replay：`docs/migration/replays/d05-original-office-file-import-fail-closed.mjs`（31 项）

## 原版行为（硬证据）

- `nj3.java`：十一种 PDFTron 转换类型 —— `doc/docx/ppt/pptx/ppsx/
  xls/xlsx/rtf/rtfd/key/pages`，各带 MIME（rtfd 无 MIME）。
- `i58.java`：选择器 `*/*`，故这些类型在原版均可选中。
- `jv5.java`：5 处 `fcaVar*.f(absolutePath, new z39(file,5), …)`
  加载调用；每处成功后统一
  `new su5(new o88(ttfVar, nj3.pdf, nj3Var3, …), (r8d) objT, 页列表)`
  ——`o88` 第一参恒为 `nj3.pdf`，第三参保留源类型；即**转换产物恒为
  PDFTron `r8d` 文档**，Office→PDF 转换发生在 PDFTron 引擎内部。
- `fca extends via`：`via.f` 是协程加载框架，`fca.e` 清理临时文件。
- `yq8.java`：`uu5Var instanceof su5` 走 PDF reducer —— 与 Phase 652
  PDF 导入下游完全同构。

## Harmony 现状与决定

- PDFKit `pdfService` 仅 `loadDocument`（解析既有 PDF）与
  `convertToImage`（PDF→图片），**无 Office/RTF→PDF 转换 API**；
  PreviewKit `filePreview` 只预览不产出字节。结构性不可等价。
- 决定（ADR-0623）：fail-closed 登记——`fileSuffixFilters` 不收录
  十一种后缀（选择器层不可选）；经分享/Intent 绕入的同类文件落
  `importFromData`，非 `.note` ZIP/manifest → `CORRUPTED` /
  `UNSUPPORTED_FORMAT`，不写半成品。
- 本阶段无 ArkTS 代码改动（fail-closed 现状即目标行为）。

## 实现/登记内容

- 专项 Replay 31 项：nj3 十一种类型声明、jv5 `fca.f` ≥4 调用点、
  `su5(nj3.pdf)` ≥4 构造点、`yq8.f` `su5` 路由、选择器逐一排除
  `.doc/.docx/.ppt/.pptx/.ppsx/.xls/.xlsx/.rtf/.rtfd/.key/.pages`、
  NoteImporter 无 `convertOffice/convertToPdf` 路径、dispatch 兜底
  `importFromData`、ZIP/manifest 兜底校验。

## 验证

- 专项 Replay：31/31 通过。
- 全量 Desktop Replay：541/541 通过（见下）。
- 无代码改动；clean + `note@ohosTest` + `note@default` 构建按流程
  照常执行（结果见提交说明/本文件更新）。
- 未进行模拟器/真机/Hypium 验证。

## 与原版的差异

| 项 | 原版 | Harmony | 说明 |
|----|------|---------|------|
| `.doc/.docx/.ppt/.pptx/.ppsx/.xls/.xlsx` | `fca.f` → PDFTron 转换 → su5 | 不可选/不可导入 | 无转换引擎，ADR-0623 |
| `.rtf/.rtfd/.key/.pages` | 同上 | 同上 | rtfd 为目录束，更无对等 |
| 选择器范围 | `*/*` | 仅已实现类型 | 不支持类型选择器层排除 |

## 影响文件

- `docs/migration/replays/d05-original-office-file-import-fail-closed.mjs`（新增）
- `docs/migration/evidence/original-office-file-import-jadx-2026-09-24.md`（新增）
- `docs/migration/adr/ADR-0623-original-office-file-import-fail-closed.md`（新增）
- `docs/migration/reports/phase-656-original-office-file-import-fail-closed.md`（新增）
- `docs/migration/audit-2026-08/修复总纲.md`、`修复总纲2.md`、
  `docs/migration/reports/修复进展-2026-08-09.md`（追加登记）

## 后续

- 若 Harmony 后续提供 Office→PDF 系统能力，可在 `importFromFile`
  分发链按 `su5` 语义接入并复用 Phase 652 全部下游逻辑。
- `nj3` 25 种类型全部登记完毕：`.note/.nbn/.ntb`（既有）、`.pdf`（652）、
  图片 9 种（653）、`.txt`（654）、音频 6 种（655）、PDFTron 转换
  11 种（本阶段）、`unknown`（原版亦 fail-closed）。
- T-042 仍为最后任务。
