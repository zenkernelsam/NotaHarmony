# Phase 791 证据：原版 1.4.2 非字符串资源面收尾登记

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——非字符串资源面全量归属。
证据源：`decompiled_1.0.3` vs `decompiled_1.4.2` `resources/res/` 目录级 diff。
Replay：`docs/migration/replays/d02-original-nonstring-resources.mjs`
ADR：`ADR-0735-original-nonstring-resources.md`

## 1. res/ 目录结构差

| 维度 | 1.0.3 | 1.4.2 | 判定 |
|------|-------|-------|------|
| values-* 目录 | 24 | 13 | vendor 裁剪（h-dp/w-dp/sw/land/
large/xlarge/ldrtl 桶消失，+values-hdpi） |
| layout-* 目录 | 3 | 1 | abc_/material_/mtrl_/design_ 存量消失 |
| color-* 目录 | 2 | 1 | vendor 色表裁剪 |
| drawable-* 密度桶 | 4 | 5 | +drawable-hdpi |
| res/xml | — | — | 仅删 m3_button_group_child_size_change |

结论：全部裁剪项为 AppCompat/Material vendor 资源——
Compose 化加深 + 依赖升级所致，无应用层行为差。

## 2. res/raw/ —— 两版完全一致

`.riv` 动画（inky 吉祥物、Learn 四主题、confetti、
designsystem grow）、PDFTron 插件四件、
`ayp_youtube_player.html` 均为 1.0.3 存量。

## 3. res/font/ —— 仅 Inter 可变字体轴差

`inter_*_opszwght.ttf` → `inter_*_wght.ttf`（去掉 opsz 轴）。
其余 16 字体两版一致。无排版行为差。

## 4. drawable/ 应用级差（476→493）

**新增**全部归属既有簇：
- calligraphy 五层图标（fill/highlight/outline/overlay/shadow）→ 778
- shape_* 六形 + shape_tool 四层 → 776
- line_style_{fixed,variable,dashed,dotted} → 778
- paper_{dotted,grid,ruled}_outline → 761
- sticker/stickermenu/your_stickers → 783
- gallery/templates nav 图标 → 774/789
- passkey → 771；file_type_{csv,rtf}/anki_flashcards → 779
- dislike_audio_transcription → 790；quizzes_explain → 788
- achieve/remix/app_mark/typestyles → 设计系统增量

**移除**均为换键：`selection_menu_convert_to_math`、
`fit_to_page`、`insert_math`、`youtube`、`toggle_on/off`
等 → `ui_designsystem__math` 等（代码核实 `m36.java`：
convert_to_math 菜单项仍在，仅图标换 designsystem 键）。
**无功能移除。**

## 5. drawable-nodpi +15

10×`ui_notecovers__cover_*.webp`（763 封面 raster 预览）
+4×`ui_planners__cover_academic_planner_2026_2027_*.webp`（782）
+1×`ui_tools__google_ink_glitter_preview_tile.webp`
（762 粒子笔刷 glitter 预览图）。

## 6. 分类结论

非字符串资源面全量归属：vendor 裁剪 + 已注册簇资产 +
Inter 字体轴微调。无未注册行为差。
