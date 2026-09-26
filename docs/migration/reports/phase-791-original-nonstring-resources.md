# Phase 791 — 原版 1.4.2 非字符串资源面收尾登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-791-original-nonstring-resources.md`
ADR：`ADR-0735-original-nonstring-resources.md`
Replay：`d02-original-nonstring-resources.mjs`（7/7）

## 本阶段做了什么

对 `resources/res/` 做目录级 diff，完成非字符串资源面
全量归属。

## 发现

- values-* 24→13、layout-* 3→1、color-* 2→1：vendor
  裁剪（Compose 化+依赖升级），无应用行为差。
- res/raw 两版完全一致（rive/PDFTron/youtube 资产存量）。
- res/font 仅 Inter 可变字体轴差（opsz,wght → wght）。
- drawable 新增全归既有簇（calligraphy/shape/line-style/
  paper-outline/sticker/gallery/templates/passkey/csv-rtf/
  anki/transcription-feedback/quizzes-explain）；
  移除项均为换键（代码核实 convert_to_math 功能仍在）。
- nodpi +15：covers×10 + planner covers×4 + glitter tile。

## 验收

- Replay 7/7 绿；全量套件与双 HAP 随本阶段执行。
- 至此 `resources/res/` 资源面全量归属完毕。
