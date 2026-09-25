# ADR-0680 widget 暗色色板（values-night）移植

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：732
- 证据：`docs/migration/evidence/original-widget-night-palette-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-widget-night-palette.mjs`
- 接续：ADR-0674（Phase 726 widget 昼值视觉对齐）

## 背景

Phase 726 按 `values/colors.xml` 昼值硬编码了 12 色 widget 视觉。
`values-night/colors.xml` 中存在完整 widget 暗色变体（11 键有夜
值，`widget_recording_button` 无夜键=原版夜间沿用昼橙），Harmony
此前 `dark/element/color.json` 仅有 `start_window_background`，
卡片在深色模式下保持昼色——与原版行为不符（原版 widget 随系统
深色切换整套色板）。

## 决策

- 12 键 widget 色落入 `base/element/color.json`（沿用原版键名
  `app_widgets__widget_*` 便于追溯）；11 个夜值落入
  `dark/element/color.json`；`widget_recording_button` 仅声明昼值
  ——Harmony 资源限定符回退语义与 Android values-night 一致
  （缺夜键=取 base），忠实复刻原版。
- 5 张卡片硬编码 hex 全部改挂 `$r('app.color.*')`：tile 底、
  主色钮、文字、占位底/图标、缩略图边框、分隔线、卡片底。
- add/record SVG 图标增 `.fillColor(on_accent)`——原版为 tinted
  vector（夜态 `on_accent=#0c0d11` 深色图标配 `#5ba8f5` 浅蓝钮）；
  烘焙白色 SVG 经 fillColor 重新着色等价实现。
- `widget_subject_bg`（`#524278ff`/`#525ba8f5`）键入册备用——
  原版 subject 面板（文件夹 widget 头部主题条）当前 Harmony 卡片
  未设该节点，登记不挂载。
- values-night 其余键（shortcut 自适应图标取色、SPen/setting_*）
  为平台/SPen 边界，不移植。

## 后果

widget 视觉从昼色固定升级为与原版一致的昼夜双态；深色模式下
卡片底/文字/分隔线/占位/按钮色全部随系统深色切换。运行时视觉
变更→真机验收清单新增暗色矩阵行。
