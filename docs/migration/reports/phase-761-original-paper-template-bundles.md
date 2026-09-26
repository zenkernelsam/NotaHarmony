# Phase 761：原版 1.4.2 内置纸张模板包格式登记

> 日期：2026-09-29
> 证据：`docs/migration/evidence/phase-761-original-paper-template-bundles.md`
> 上层处置：`docs/migration/adr/ADR-0708-original-1.4.2-version-delta-scope.md`（版本差·待审）
> Replay：`d02-original-paper-template-bundles.mjs`（9 断言，全绿）
> 性质：版本差证据登记；无 Harmony 源码变更。

## 背景

Phase 760 在 `resources/assets` 层面发现 1.4.2 新增 `papertemplates/`
目录（446 文件、35 包）——这是模板中心改版（`ui_templates__*`/
`ui_papertemplates__*` 族）的资源底座。本阶段把包格式登记为可复核证据。

## 登记结果

- **包结构**：每包 `metadata.json` + `{Name}_{Size}_{hex}_{orientation}.pdf`
  组合底板 + `thumb{,_black}{,_landscape}.{heic,png}` 缩略图；
- **metadata schema**：`uuid / name / paperSizes / defaultPaperSize /
  colors / category`，category 值域与 `ui_papertemplates__{academic,
  creative,notepads,planning,self_care}` 字符串族一一对应；
- **命名规则**：PDF 数 = sizes×colors×方向变体数；双方向包带
  `_landscape/_portrait` 后缀（cornell 6×3×2=36），单方向包省略方向段
  （isometic `Isometic_A4_000000.pdf` 2×2×1=4）；
- **35 包全目录**落盘于证据文档第二节（notepads 10 / planning 9 /
  academic 5 / selfCare 6 / creative 5），含米字格、田字格、Cornell、
  manuscript、engineering_grid 等；
- **缩略图**：HEIC 49 件 + PNG 18 件混用。

## 与 1.0.3 纸张体系关系

1.0.3 纸张为代码生成（PLAIN/LINES/GRID/DOTS + legacy + 自定义色/间距，
NotaHarmony `OriginalTemplatePickerState` 已等价）；1.4.2 papertemplates
是整页 PDF 底板资产，与生成式纸张并存，不取代原语义。

## 处置与验收

- 登记为 ADR-0708"版本差·待审"——资产纯本地理论可移植，
  但需独立 Phase 评估 Harmony PDF 底板渲染链与 HEIC/PNG 处理；
- Replay 9 断言全绿（schema、命名规则、35 包基数、缩略图混合格式、
  证据文档登记）；
- 无 Harmony 代码变更；T-042 仍为 Goal 最后一项，本登记为其输入。
