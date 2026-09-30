# Phase 1360 中文报告 — UI 措辞保真修正（第三批）

## 背景

延续 Phase 1358/1359 的实改路线：逐键比对原版 `strings.xml` 与 Harmony `string.json`，
修正真实措辞/大小写差异。本批为第三批，覆盖跳转对话框、工具箱菜单、通用对话框按钮
与加载/文件夹/模板/字体设置等语境。

## 修正内容

### 英文（base）13 处

| 键 | 旧值 | 新值 | 原版键 |
|----|------|------|--------|
| jump_to_title | Jump to page | Jump to | feature_note__jump_to_title |
| jump_to_page_label | Page number | Page | feature_note__jump_to_page_label |
| add_files | Files | Add Files | feature_note_toolbox__add_files |
| insert_math | Math (LaTeX) | Insert Math | feature_note_toolbox__insert_math |
| take_photo | Take a photo | Take Photo | feature_note_toolbox__take_photo |
| reset_to_default | Reset to Default | Reset to default | feature_note_toolbox__reset_to_default |
| new_folder | New Folder | Create new folder | ui_folder__new_folder |
| template_settings | Template Settings | Template settings | ui_templates__template_settings |
| font_family | Font | Font family | ui_text__font_family |
| confirm | OK | Confirm | ui_designsystem__confirm |
| dismiss | OK | Dismiss | ui_permissions__dismiss / ui_fileimport__dismiss |
| loading | Loading... | Loading… | ui_fileimport__loading |
| record_audio | Record audio | Record | feature_note__empty_note__record_audio |

### 中文（zh_CN）4 处同步

`dismiss` 好→取消；`loading` 加载中...→加载中…；`add_files` 文件→添加文件；
`insert_math` 公式 (LaTeX)→插入公式。

## 判定原则

- 逐键核对**完整原版键名**与 Harmony **调用点语境**，仅修正同语境确证差异。
- 刻意保留：转义等价（`\'`）、位参等价（`%s`/`%1$s` 顺序传参渲染相同）、
  不同功能语境的同末段键（`restore_failed` 备份告警 vs 订阅恢复）、产品名 `app_name`、
  已正确的 Title Case `select_all`/`deselect_all`（库/页面选择语境）。
- 无中文原版基线（APK 无 `values-zh`），中文值按新英文语义同步、取自然译法。

## 验证

- `d02-wording-fidelity-b3.mjs`：**10/10** 通过（含 Phase 1358/1359 回归守卫）。
- 两 JSON 均有效；`note@default` HAP 构建成功（仅既有 deprecation 警告）。

## 结论

累计本会话修正 30 处 UI 文案（1358:7、1359:6、1360:17），全部对齐原版证据或
语境语义。剩余同名候选多为跨功能前缀碰撞、转义等价或非便携功能的刻意适配，
逐点核对后不属于真实缺陷。
