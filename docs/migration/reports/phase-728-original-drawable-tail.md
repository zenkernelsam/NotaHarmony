# Phase 728 中文报告：drawable/mipmap/anim/layout 族收口登记

## 范围

`res/drawable*` 482 件 + `mipmap-*` + `{anim,animator,interpolator,color}`
+ `layout*` 应用级键——非字符串资源审计末族（文档级收口）。

## 原版证据

见 `docs/migration/evidence/original-drawable-tail-jadx-2026-09-25.md`：
482 件按前缀分桶（ui_designsystem 216 图标、SPen/qt ≈140 内部件、
库级件 ≈70、widgets 19、shortcuts 6、paper 15、login/settings
社交图标 15、selection_menu 9、brushstyle+strokeindicator 28、
tape_pattern 11、text-format 17、pressure 2、laser 2 等）。

## 结论

- 已移植/程序化等价桶全在位校验：widgets（Phase 726）、shortcuts、
  papers、TapePatternPicker 九图案程序化预览、OriginalLaserPointer、
  PencilSplatGenerator。
- 文本化惯例延续（ADR-0668 先例）：toolbox/selection/text-format/
  brushstyle 图标 → 文本标签按钮，icon 节点 a11y 已在文本节点等价。
- 边界桶登记：feature_login__*、feature_settings__ 社交行
  （instagram/youtube/tiktok/threads/linkedin/star——原版 g8.java
  About 区五行图标，Harmony 无 About 子页）、hwr_toggle/youtube
  （ADR-0670/0651）、SPen/qt/pressure/setting_*（ADR-0672/P709）、
  anim/animator/interpolator/color/mipmap 平台件、values-* 限定符机制。
- 至此 `res/` 全资源族闭合。

## 验证

- `d02-original-drawable-tail.mjs` 全绿。
- 全量 Desktop Replay 全绿；双 HAP clean 构建成功（无代码变更）。
