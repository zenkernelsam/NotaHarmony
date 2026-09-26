# 原版 1.4.2 封面资产与贴纸 split 登记（Phase 763 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/resources/assets/covers/` 与
>   `Notability_1.4.2/*.xapk` 内 `stickers.apk` split（1.0.3 均无对应物）
> 性质：1.4.2 版本差证据登记（ADR-0708"版本差·待审"细化）；无 Harmony 代码变更。

## 一、`covers/` 内置笔记封面（10 件，均 PDF-1.7）

| 文件 | 大小 |
|------|------|
| blue.pdf / orange.pdf / sage.pdf / yellow.pdf | 6~8 KB |
| brown.pdf / maroon.pdf | 27 KB |
| logo-pattern.pdf | 46 KB |
| blue-journal.pdf / purple-journal.pdf | 65~90 KB |
| stickers.pdf | 105 KB（封面贴纸预设页，对应 `ui_notecovers__preset_stickers`） |

无清单文件——封面集合在代码中枚举（`ui_notecovers__*`/`feature_library_gallery__`
编辑封面流程），资产形态为整页 PDF 位图底板。

## 二、`stickers.apk` 独立 split（156,242,475 B，xapk 成员）

- 结构与 base APK 并列（AndroidManifest + META-INF + assets/），
  运行时按 split 按需下发——贴纸商店的分发通道本体；
- `assets/` 下 **39 个内置贴纸包目录，共 ~2985 个 .webp 贴纸**：

  大体积包：sticker_konana_academic(552)、sticker_dash_planning(498)、
  sticker_ellagant_planning(390)、sticker_ellagant_bullet_journal(208)、
  sticker_dash_patterned_washi(112)、sticker_dash_essential_shapes(96)、
  sticker_bloom_teachers_essentials(78)、sticker_ellagant_holiday(63)、
  sticker_mia(62)；其余 30 包各 12~51 件（abstract_backgrounds/
  at_school_basics/back_to_school/bloom_*/cheerful_friends/
  chinese_new_year_2022/colorful_*/cozy_at_home/dash_*/earth_day*/
  fall2024/garden_blooms/halloween_bundle_2020/happy_girl/
  joyful_valentines/lei_qizai/lin_chen/minimalist_1/pastel_sticky_notes/
  planning_pals/stem_*/study_success/tasty_recipe/under_the_sea/
  winter_2021）。

- 包内无独立清单——包目录与 `feature_note_stickers__pack_*`
  字符串键（~40 个）一一对应，商店元数据在代码/服务端；
- 另有 `StickerPackDownloadWorker`/`StickerPackPrefetchWorker`（新增簇表）
  负责远端包下载——内置 39 包 + 远端扩展的混合分发。

## 三、处置

- 封面 PDF：本地资产可移植候选（PDF 底板渲染链与 papertemplates 同源，
  Phase 761 已登记同型问题）；
- 贴纸 split：分发通道绑定 Play Store split-APK 机制，Harmony 无等价物；
  贴纸本身为 webp 图像（本地可渲染），但商店/下载链路属后端边界——
  登记为版本差 fail-closed（商店）+ 待审（本地插入自制贴纸 `save_as_sticker`）。
- 本阶段仅登记；均不进入 1.0.3 基线移植范围。
