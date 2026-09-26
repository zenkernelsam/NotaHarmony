# ADR-0796 — emoji 目录资产与杂项尾部

- 状态：已接受（含缺陷修复）
- 证据：`docs/migration/evidence/phase-852-emoji-catalog-assets.md`
- 回放：`docs/migration/replays/d02-emoji-catalog-assets.mjs`（12/12）

## 决定

1. `emojis_unicode.json` 登记为文件夹 emoji 选择器本体资产：
   1,913 条 × 9 category（emoji/description/category/aliases/
   tags/unicode_version/ios_version）——此前
   `LibraryPage` 注释称本体"不可见"有误，实为 assets JSON。
2. **缺陷修复**：Harmony 179 条策划子集中 4 条自 Phase 540
   起即为 U+FFFD 替换符（Objects✂️、TravelPlaces🕌🛕🕍），
   依原版目录次序语义位修复。
3. 杂项尾部登记：`ConversionRates.csv`（Stripe 本地化换算，
   fail-closed）、`PublicSuffixDatabase.list`（平台库数据）、
   `planners/` 学术 PDF 种子（归口 planner 域）。

## 后果

assets 面闭合；修复 4 个不可见损坏 emoji（选择器网格中
显示为占位符的真实缺陷）。
