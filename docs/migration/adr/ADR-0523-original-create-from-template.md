# ADR-0523: 原版新建表单 Templates 行（从模板新建笔记）

日期：2026-09-22（Phase 552）

## 背景

原版 `cd.java` case 0 的新建表单含 Import → Templates → Doc scan → Create note
四行；Templates 行打开模板选择后以所选纸张新建笔记。Harmony Phase 545 已把
speed-dial 移植 Record audio / Import file，但新建仍固定使用偏好里的默认模板，
缺少"选模板新建"路径。

## 决策

1. 在 speed-dial 末尾新增 `templates` chip（`app.string.templates`），打开
   `TemplatePickerDialog`——四款可移植纸张 PLAIN/LINES/GRID/DOTS 的网格选择。
2. 新建管线全程不改全局默认模板偏好：`createNote(title, folderId,
   templateOverride?)` 在仓储层内解析默认模板后，仅在有覆盖时调用
   `applyOriginalPaperSettings(default, size, override, orientation)` 替换
   `template` 字段，尺寸/方向继承解析结果，再走同一
   `persistOriginalBlankNoteBootstrap`。
3. `createFromTemplate` 复用 `createAndLaunch` 的守卫与生命周期语义
   （`pageActive`/`createBusy`/`lifecycleGeneration`/`openFailed`）。

## 理由

- 与原版一致：从模板新建不改动用户的默认模板设置（原版 Templates 页是一次性
  选择而非改偏好）。
- 复用既有 bootstrap/锁/失败语义，避免并行建笔记路径。
- flag 化且不可移植的完整模板管理页与 Doc scan 不实现，已在证据文档登记。

## 备选

- 临时改写默认模板偏好再还原：会产生并发窗口与崩溃残留状态，弃用。
- 在 bootstrap 内部加参：保持 bootstrap 语义单纯，覆盖在仓储层合成，更贴近
  原版"选择 → 以所选模板新建"的一步动作。
