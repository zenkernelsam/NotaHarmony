# Phase 790 证据：原版 1.4.2 字符串差尾部族合并登记

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——字符串面收尾。
证据源：`decompiled_1.4.2` strings.xml 五个尾部族。
Replay：`docs/migration/replays/d02-original-key-tail.mjs`
ADR：`ADR-0734-original-key-tail.md`

## 1. ui_text__ +16（文本面板 a11y/快捷键标签）

- 字体面板导航：`back_to_font_styles`/`close_font_styles`/
  `font_styles`/`fonts`/`colors`/`sizes`/`selected`。
- 超链接编辑：`clear_link_title`/`clear_url`/`close_hyperlink`/
  `confirm_hyperlink`（Phase 757 链接面已移植，键为增量）。
- **kbd_shortcut_***：bullet/checkbox/numbered list +
  font-size 增减的五条快捷键 a11y 标签——Harmony 快捷键
  已移植，标签为增量。

## 2. feature_note_toolbox__ +8

`add_media`/`add_sticker`/`more_tools`/`cd_hide_tools`/
`cd_playback_position`/`phone_*_tools_description`——
工具箱"添加媒体/贴纸"入口与手机形态工具面板 a11y。

## 3. feature_learn_transcription__ +10

转写查看器：`smart_notes`/`search`/`copy`/`cd_close_search` +
**转写质量反馈** `transcript_accurate`/`transcript_inaccurate` +
错误键 `error_{bad_file_format,file_too_large,no_network,
unknown}`——服务端转写面（fail-closed）+ 质量回传。

## 4. ui_permissions__ +4

`calendar_access_{rationale,required}`（765 族）+
`camera_{capture_failed,needs_unlock}`（760 IMAGE_CAPTURE_SECURE
配套：锁屏相机需解锁语义）。

## 5. ui_designsystem__ +6+

`beta`/`early_access` 徽标 + 计划本引导 +
`clear_search`/`app_mark_path`（底部表单拖柄 a11y 四键
系 1.0.3 存量，非增量）。

## 6. 分类结论

- 全部族：版本差/边界随既有簇登记；无独立新功能面。
- kbd 快捷键 a11y 标签与 bottom-sheet a11y：本地小增量。
- 转写反馈/calendar 权限理由：边界随族。
- 字符串面至此全族归属完毕（总 +722 键）。
