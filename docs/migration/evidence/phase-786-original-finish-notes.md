# Phase 786 证据：原版 1.4.2 "Finish Notes" AI 管线 + 配套键面

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2` strings.xml `feature_note__*` 差集
（+53）、`defpackage/{ezi,mf2}.java`。
Replay：`docs/migration/replays/d02-original-finish-notes.mjs`
ADR：`ADR-0730-original-finish-notes.md`

## 1. Finish Notes 管线（24 键，后端 AI 边界）

- 入口：`options_menu_finish_notes`/`cancel_finish_notes`。
- 状态机：`status_uploading → status_transcribing →
  status_generating`——上传录音→转写→生成补全的三段管线。
- 运行态：`banner_title`/`finishing`/`finished`/`stop`/`keep`/
  `dismiss`/`try_again`/`try_now`。
- 错误面：`offline`/`retryable_failure`/`terminal_failure`/
  `transcription_failed`/`transcription_unavailable`/
  `recording_still_processing`/`needs_more_content`/
  `edited_while_finishing`/`apply_failed`。
- 门控：`quota_reached`/`upgrade`/`upgrade_to_finish`——
  订阅配额。
- `ezi` 证实笔记态持 `finishNotesOffered` 标志。

## 2. 配套新键（feature_note__ 差集余部）

- `cd_*_page*` 八键：页管理器 a11y——select/deselect/
  bookmark/unbookmark/copy/delete/duplicate/clear
  numbered pages（cd_select_page_numbered 等）。
- `content_manager_add_note_cover`：封面选择入口
  （接 Phase 782）。
- `gif_picker_title`：**GIF 插入面**（新媒体源）。
- `selection_menu_paste_image`：选择菜单粘贴图项。
- `phone_title_placeholder`/`phone_title_rename`：
  手机形态标题编辑。
- `options_menu_page_manager`/`text_only`（773 已登记）、
  `toprighttoolbar_handwriting_recognition`（HWR 入口 a11y）。

## 3. Harmony 现状

- 无 Finish Notes/GIF 面；页管理器 a11y 命名已移植。
- `feature_library_gallery__`/`ui_gallery__`（142 键）为
  Phase 774 面的键级清单——存量登记不重复展开。

## 4. 分类结论

- Finish Notes：后端 AI 管线（上传/转写/生成）+订阅配额
  → fail-closed。
- GIF 插入：媒体源面，需源端适配评审（Tenor/GIPHY 类后端
  或本地 GIF 库待查）——暂记版本差。
- 页管理器 a11y 增量：本地化标签族，随 a11y 面登记。
