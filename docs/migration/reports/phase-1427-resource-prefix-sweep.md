# Phase 1427：资源前缀扫描收口报告（裁决阶段，零代码改动）

- 日期：2026-10-01
- 状态：完成（裁决阶段；Desktop Replay 9 项本 Phase 检查）
- 证据：`docs/migration/evidence/phase-1427-resource-prefix-sweep.md`
- 决策：`docs/migration/adr/ADR-1362-resource-prefix-sweep.md`
- Replay：`docs/migration/replays/d02-original-resource-prefix-sweep.mjs`

## 目标

收口 `strings.xml` 前缀扫描的最后未裁决族：`pen_palette_*`/
`pen_swatch_*`/`pen_string_*`（约 204）、`ui_templates__*`（59）、
`ui_notecovers__*`（14）、`ui_papertemplates__*`（15）、vendored 族。

## 裁决结果

### 已移植

- `ui_notecovers__*`：NoteCoverSheet 10 preset（ADR-1341）。
- `ui_papertemplates__*` 类别：`paper_templates_cat_*`。
- bundled 模板图库：PaperTemplateGallery recents/favorites/类别。
- 预设色井 a11y 的 `pen_palette_color_*`/`pen_swatch_color_*` 子集
  （ColorPicker.ets 同名键逐色映射）。

### fail-closed（文书化）

- 其余 158+ `pen_palette` 命名片与 `pen_string_*`：消费方全在
  `com.samsung.android.sdk.pen.*` 随包调色板，无 Harmony 宿主。
- `ui_templates__*` 远端 Gallery 搜索/翻页（xcm/rsh 远端契约）。
- My Templates/save_as_template：`rd5` InternalUserOnly 门控，
  原版自身未发布。
- 多页模板 select_pages（olm.a）：仅远端包可达。
- `repeat_template`/`interactive_template`：1.4.2 死字符串。
- vendored 族：m3c_/mtrl_/ids_/dream_/firebase_/google_/abc_/
  androidx_/call_/common_/nav_/notification_/preference_/exo_/
  fk_/material_/generic_/tooltip_ 等库内部资源。

## 验证

- `d02-original-resource-prefix-sweep.mjs`：9/9 通过。
- 全量 Replay 基线、`note@default`、clean `note@ohosTest` 见提交说明。
