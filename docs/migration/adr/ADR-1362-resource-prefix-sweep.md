# ADR-1362：资源前缀扫描收口裁决（pen_palette/ui_templates/vendored 族）

- 状态：Accepted
- 关联：ADR-1341（NoteCoverSheet 子集）、ADR-1337（bundled 模板 apply）、
  evidence `phase-1427-resource-prefix-sweep.md`

## 背景

原版 1.4.2 `strings.xml` 前缀扫描的最后未裁决族：`pen_palette_*`/
`pen_swatch_*`/`pen_string_*`（约 204 键）、`ui_templates__*`（59）、
`ui_notecovers__*`（14）、`ui_papertemplates__*`（15）及 vendored
库字符串族。

## 裁决

### 已移植（无需动作）

- `ui_notecovers__*`：`NoteCoverSheet` 10 preset + 预览 + Cancel/Done。
- `ui_papertemplates__*` 类别键：`paper_templates_cat_*` 全量在。
- bundled 模板图库：`PaperTemplateGallery`（recents/favorites/类别）。
- `pen_palette_color_*`/`pen_swatch_color_*` **预设色井 a11y 子集**：
  `ColorPicker.ets` 按同名键逐色映射——原命名键保留，标签逐字对齐。

### fail-closed

- `pen_palette_color_*` 其余 158+ 命名片 + `pen_string_*`：消费方全在
  `com.samsung.android.sdk.pen.*`（S Pen SDK 随包调色板），Harmony
  无宿主。
- `ui_templates__*` 远端 Gallery 搜索/翻页（`xcm`/`rsh` 远端契约）。
- My Templates 增删改 + save_as_template：`rd5` InternalUserOnly
  门控，原版 1.4.2 亦不向用户发布。
- 多页模板 select_pages（`olm.a`）：仅远端 Gallery 包可达。
- vendored 族（m3c_/mtrl_/ids_/dream_/firebase_/google_/abc_/androidx_
  /call_/common_/nav_/notification_/preference_/exo_/fk_/material_/
  generic_/tooltip_ 等）：库内部资源，无应用层语义。
- `repeat_template`/`interactive_template`：1.4.2 死字符串。

## 结论

`strings.xml` 前缀扫描至此收口：全部非 `__` 族为 vendored，`__` 族
均已移植或 fail-closed 并留 ADR 痕。后续 Phase 转向行为/渲染层剩余
差异复核与新增发现的缺口。

## 验证

`d02-original-resource-prefix-sweep.mjs` 9 项断言全绿；
全量基线与双构建见 Phase 1427 报告。
