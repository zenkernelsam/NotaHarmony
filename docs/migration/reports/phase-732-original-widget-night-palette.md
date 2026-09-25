# Phase 732 中文报告：widget 暗色色板（values-night）移植

## 范围

`values-night/colors.xml` 中 11 键 widget 夜值——Phase 726 昼值
对齐的深色半面补齐。

## 原版证据

见 `docs/migration/evidence/original-widget-night-palette-jadx-2026-09-25.md`。
要点：`widget_on_accent` 夜态翻转 `#0c0d11`（浅蓝钮上深色图标的
tinted-vector 语义）；`widget_recording_button` 无夜键（夜间沿用
`#ffa629` 昼橙，Android 限定符回退）。

## 本阶段变更

- `base/element/color.json`：新增 12 键昼值（沿用原版
  `app_widgets__widget_*` 键名）。
- `dark/element/color.json`：新增 11 键夜值（无 recording_button
  ——回退语义与原版一致）。
- 5 张 form 卡片（NewNote/NewRecording/RecentNotes/FolderNotes/
  NoteThumbnailCard）：硬编码 hex 全改 `$r('app.color.*')`；
  add/record SVG 增 `fillColor(on_accent)` 对齐 tinted-vector。
- `widget_subject_bg` 入册备用（原版 subject 面板 Harmony 无节点）。
- `values-night` 其余键（shortcut 取色、SPen/setting_*）平台/SPen
  边界登记。

## 验证

- `d02-original-widget-night-palette.mjs` 专项全绿。
- 全量 Desktop Replay 全绿；双 HAP clean 构建成功。
- 运行时视觉变更（深色模式 widget 取色）→ 真机验收新增暗色矩阵行。
