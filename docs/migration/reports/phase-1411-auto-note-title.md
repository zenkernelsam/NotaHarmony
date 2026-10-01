# Phase 1411 修复报告：Document Defaults 自动笔记标题

## 范围

移植原版 1.4.2「文稿默认值 → 默认笔记标题」特性：偏好持久化
（`noteEditorSettings` 三键）、`mcn.g` 自动标题格式化、建笔记时
生成、`note_title` 设置子屏（字段+清除钮+include date/time 三态
+Example 预览）。Harmony 此前新笔记恒为 `"New Note"`（flag-off
分支等价），本阶段补齐完整链路。

## 原版证据（decompiled_1.4.2）

- `o8b.java`：DataStore `noteEditorSettings`；键
  `defaultNoteTitle`/`includeDatePosition`/`includeTimePosition`。
  解码缺省：title→null、date→`hmi.SUFFIX`、time→`hmi.NONE`；
  `o8b.f` 中 `j8b.z != null → str = str2`（空串覆盖 fallback）。
- `mcn.g`：`zq.M`=日期 MEDIUM、`zq.e`=时间 SHORT
  （`tgh(10)`/`tgh(11)` = ofLocalizedDate/Time）；前缀→基题→后缀
  组装，`r0h.T0` 丢空、空格 join。
- `k59.l`：旗标 `h35.R0=DOCUMENT_DEFAULT_SETTINGS`（`qd5` 调试
  门控）关→`k()`="New Note"；开→`o8b.f(fallback="Note")`，
  blank→`"..."。`
- `je` case11：草稿 ≤200 码元；`yob` 字段非空尾部
  `xmark_circle_fill` 清除；`ibb` 三态行尾显示当前标签；
  `a96` Example 用 `remember{now}` 且不套 fallback。

## Harmony 实现

- `EditorSettingsStore`：同名 store 同键；`getDefaultNoteTitle`
  缺键→null、存 `''`→`''`；`sanitizeTitlePosition` 非法值回缺省。
- `OriginalNoteTitlePolicy`：`NOTE_TITLE_POSITION_*` +
  `formatOriginalAutoNoteTitle`（Intl medium/short、`/\S/` 判
  blank、join(' ')）+ `ORIGINAL_AUTO_TITLE_EMPTY_FALLBACK='...'`。
- `LibraryViewModel.createNote`：注入 `noteTitleFactory`，建库行
  内 `Date.now()` 生成；缺失/异常 fail-closed→"New Note"。
- `LibraryPage`：工厂读三偏好+本地化 "Note" fallback→formatter
  →blank→"..."。
- `SettingsPage`：Document Defaults 区（200 上限 TextInput +
  合成 xmark_circle_fill 清除钮 + 两三态行 + TitlePositionDialog
  + Example 预览），写入沿用乐观更新/回滚/toast 模式（文本直写
  不回滚——回滚会打断打字）。

## 有意差异（ADR-1347）

- 特性 flag-off 于原版出货包；Harmony 无条件开放。默认配置下
  新笔记标题 = "Note <medium date>"（原版 flag-on 设计行为）。

## 验证

- 新增 `d02-original-auto-note-title.mjs`：112 checks，双端锚定。
- 重锚定 `d02-local-set-metadata-title-outbound.mjs` /
  `d02-original-create-from-template.mjs`（factory 化 createNote）；
  `/\S/` 替换 `.trim(` 守住「标题字段禁 trim」pin。
- `note@default` / `note@ohosTest` HAP 构建通过；全量基线
  1263/1263。
