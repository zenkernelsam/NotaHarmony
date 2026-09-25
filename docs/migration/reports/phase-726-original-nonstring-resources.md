# Phase 726 中文报告：非字符串资源尾部（app_widgets 视觉对齐 + 边界登记）

## 范围

strings/plurals 收口后推进到其余资源族：arrays/bools/integers/dimens/
styles/colors + `app_widgets__*` 布局/drawable。除 widget 调色板与
缩略图圆角外全部为 SPen SDK / GMS / Compose-M3 平台内部键。

## 原版证据

见 `docs/migration/evidence/original-nonstring-resources-jadx-2026-09-25.md`：

- `colors.xml` 12 个 `app_widgets__*` 键逐字色值；
- `dimens.xml` `widget_thumb_corner_radius`=6dp
  （`WidgetImageProvider.java:106`）；
- `create_note_widget.xml`/`create_recording_widget.xml`：20dp 圆角
  着色 tile + 左上着色标签 + 左下 40dp r12 主色钮（#4278ff / #ffa629）
  + 白色图标；
- `widget_notes_row.xml`：r6 缩略图框（#f6f6f8 底+1px #e8ebf0）、
  标题 #0c0d11、每行无条件 1dp #e8ebf0 分隔线；
- `widget_note_thumbnail.xml`：fitXY 拉伸、#f6f6f8 r16 占位、
  #ffffff r16 卡片底。

## 变更

- `NewNoteCard.ets`/`NewRecordingCard.ets`：重写为原版 tile 结构——
  着色底 #ecf2ff/#fff6ea r20、左上标签 #171a20、左下 40×40 r12 主色钮
  #4278ff/#ffa629 内嵌新 `widget_add`/`widget_record` SVG（白）。
- `RecentNotesCard.ets`/`FolderNotesCard.ets`：缩略图 r6+1px #e8ebf0
  边框；占位格 #f6f6f8+#c8cfdb；标题 #0c0d11；分隔线改每行 1px
  #e8ebf0；卡片底 #ffffff r16；头部 #0c0d11。
- `NoteThumbnailCard.ets`：占位 #f6f6f8 r16+#c8cfdb；ImageFit.Fill
  （对齐 fitXY）；卡片底 #ffffff r16。
- 新增 `widget_add.svg`/`widget_record.svg`（原版向量路径逐字移植）。

## 边界登记（ADR-0674）

arrays.xml 79 键（SPen swatch/adaptive 数组 + learn chat headers）、
bools.xml（Firebase/WorkManager）、integers.xml + dimens.xml 的
`qt_*`/`quick_tool_*`（SPen QuickTools 盘，Phase 709 边界）、
styles.xml（AppTheme/ThemeSplash/AppCompat/M3）——全部平台或 SDK
内部，fail-closed。`widget_subject_bg` 左侧主题面板无 Harmony 结构
对应挂载点，登记为布局差异。

## 验证

- `d02-original-widget-visuals.mjs` 全绿。
- 全量 Desktop Replay 全绿。
- `note@ohosTest` + `note@default` clean 构建成功，无新增 ArkTS 错误。
