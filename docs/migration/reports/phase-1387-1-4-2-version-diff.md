# Phase 1387 — 1.0.3↔1.4.2 版本差异摸底报告

## 目标

落实交接文档 P3 前置项：对 1.4.2（AI Note Workspace，versionCode 1040002）相对
1.0.3（versionCode 1014）做差异摸底，找出新增功能 / 行为变更 / 需同步项，为后续
按特性逐个 Phase 移植或定 fail-closed 提供底账。

## 方法

1.4.2 已完成 jadx-1.5.6 反编译（24808 源 / 493 drawable）。因 `defpackage` 为混淆层
（18563→21993，逐名 diff 无意义），改用三类有效信号源：
- `com.gingerlabs.notability` 未混淆包目录 diff；
- `resources/res/drawable` diff（净 +17）；
- `AndroidManifest.xml` 组件/权限 diff + 字符串命名空间 diff（+722/−107）。

## 关键结论

- **规模**：+3,700 源（+17%）、+17 drawable、+722 字符串 —— 大版本跃进。
- **新组件/权限**：`HwrEngineService`（MyScript HWR）、`ApiGatedFirebaseInitProvider`、
  `READ_CALENDAR`。
- **新特性面**：Learn AI 学习套件（flashcards/quiz/AI tutor/transcription/syllabus）、
  社区图库（131 字符串，collections/comments/followers）、Shape 工具（6 形状）、
  Calligraphy 笔刷（第 5 样式）、贴纸（packs）、模板、passkey、付费墙、纸样/线型、
  CSV/RTF 导入。
- **移植分类**：A 类本地可移植（shape/calligraphy/线型/贴纸放置/本地模板/CSV-RTF/纸样）
  进入后续 Phase；B 类后端依赖（Learn/社区图库/转写/passkey/HWR/付费墙/云同步/日历）
  走 fail-closed。

## 产出

- 证据：`docs/migration/evidence/phase-1387-1-4-2-version-diff.md`
- ADR：`ADR-1323`
- Replay：`d02-1-4-2-version-diff.mjs`（13 项）
- 跟踪：修复总纲 / 修复总纲2 / 修复进展-2026-08-09

## 验证

- Replay fixture：13/13 绿。
- 全量 Desktop Replay：基线全绿（见提交说明）。
- note@ohosTest / note@default：clean 构建成功。
