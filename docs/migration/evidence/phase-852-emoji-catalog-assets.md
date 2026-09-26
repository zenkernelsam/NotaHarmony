# Phase 852 — emoji 目录资产 + 杂项资产尾部

证据：`decompiled_1.4.2/resources/assets/` 尾部盘点。

## 一、`emojis_unicode.json`（1,913 条）

字段：`emoji`/`description`/`category`/`aliases`/`tags`/
`unicode_version`/`ios_version`。九类分布：

| category | count |
|----------|-------|
| Smileys & Emotion | 171 |
| People & Body | 387 |
| Animals & Nature | 160 |
| Food & Drink | 131 |
| Travel & Places | 219 |
| Activities | 85 |
| Objects | 266 |
| Symbols | 224 |
| Flags | 270 |

即文件夹 emoji 选择器的数据源（LibraryPage 注释的
`du3` 九类 = 此 JSON 的 9 category）。

## 二、Harmony 缺陷修复（实证）

`LibraryPage.FOLDER_EMOJI_CATEGORIES` 179 条策划子集中
**4 条自始为 U+FFFD 替换符**（Phase 540 引入即坏）：

- Objects idx109 `'\ufffd\ufe0f'` → 修复为 `✂️`
  （U+2702+FE0F，文具簇 ✏️🖊️📐📏✂️ 语义位）；
- TravelPlaces idx137-139 `'\ufffd'`×3 → 修复为
  `🕌🛕🕍`（宗教建筑簇，JSON ⛪ 后的次序位）。

修复后以 `emojis_unicode.json` 为原版本体登记。

## 三、其余尾部资产

- `ConversionRates.csv`：Stripe 价格本地化换算表
  （9/1/24 币种行：AED/PHP/ZAR/VND/USD…）——计费后端
  辅助数据，fail-closed；
- `PublicSuffixDatabase.list`：公共后缀表（URL 域解析，
  OkHttp/链接化使用）——平台库数据；
- `planners/`：学术 planner PDF 种子（2026-2027
  monday/sunday 变体）——已归口 planner 资产域；
- `mlkit-google-ocr-models`/`conf/`/`spellcheck`/`glmath/`/
  `covers/`/`papertemplates/`/`brushpacks/`/`dexopt`/
  `resources`/`app/rive` 均已在前序相位归口。

## 四、结论

assets 面完全闭合；emoji 目录发现本体资产并修复 Harmony
4 条损坏条目。
