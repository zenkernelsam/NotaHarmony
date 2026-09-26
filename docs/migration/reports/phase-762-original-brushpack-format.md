# Phase 762：原版 1.4.2 笔刷包（.brushpack）格式登记

> 日期：2026-09-29
> 证据：`docs/migration/evidence/phase-762-original-brushpack-format.md`
> 上层处置：`docs/migration/adr/ADR-0708-original-1.4.2-version-delta-scope.md`（版本差·待审）
> Replay：`d02-original-brushpack-format.mjs`（8 断言，全绿）
> 性质：版本差证据登记；无 Harmony 源码变更。

## 背景

Phase 760 资产 diff 发现 1.4.2 新增 `brushpacks/`（5 个 .brushpack），
对应 `ui_tools__brushstyle_calligraphy`/`ui_designsystem__calligraphy_*`
图标族——原版在 1.4.2 引入书法/粒子笔型。本阶段登记容器与清单格式。

## 登记结果

- `.brushpack` = ZIP：`manifest.json` + `brush_family.proto` +
  `preview_well.png` + `preview_selection.png`；
- manifest schema：`displayName / fallbackColor / fallbackWidthDp /
  tintable` + 可选 `tintBlendMode: "multiply"` / `tintAlpha`；
- `brush_family.proto` 为 gzip 压缩 protobuf（粒子/图章族定义，
  rainbow 解出族标识 `fun-a-unstable`）；五包清单全量落盘证据文档；
- proto 字段语义与粒子渲染链需独立 Phase 还原，本阶段仅登记格式。

## 验收

- Replay 8 断言全绿（容器、schema、gzip 包层、族标识、multiply 色键）；
- 无 Harmony 代码变更；版本差·待审登记，T-042 输入。
