# Phase 852 — emoji 目录资产 + 杂项资产尾部

## 范围

`assets/` 尾部：`emojis_unicode.json`、`ConversionRates.csv`、
`PublicSuffixDatabase.list`、`planners/`。

## 原版发现

### `emojis_unicode.json`（1,913 条）

emoji/description/category/aliases/tags/unicode_version/
ios_version；九类（Smileys 171、People 387、Animals 160、
Food 131、Travel 219、Activities 85、Objects 266、
Symbols 224、Flags 270）= 文件夹 emoji 选择器数据源。

### 杂项

- `ConversionRates.csv`：币种换算（Stripe 本地化，fail-closed）；
- `PublicSuffixDatabase.list`：公共后缀表；
- `planners/`：2026-2027 学术 planner PDF 种子。

## Harmony 缺陷修复

`FOLDER_EMOJI_CATEGORIES` 179 条子集中 **4 条自始为
U+FFFD**（Phase 540 引入即坏，此前未检出）：

- Objects：✂️（文具语义位）；
- TravelPlaces：🕌🛕🕍（宗教建筑簇次序位）。

## 验证

- Replay `d02-emoji-catalog-assets.mjs`：**12/12**（目录
  字段/分布、Harmony 修复后断言、资产存在性）。
- 全套 Replay：**725/725**。

### 回归备注

U+FFFD 修复脚本轮次曾将 `LibraryPage.ets` 行尾从 LF 写成
CRLF（Python 文本模式写文件的 Windows 默认转换），导致 4 个
按 `\n` 切片解析源码的旧 Library fixture 失配（套件
721 passed / 4 failed）。已用二进制方式恢复全文件 LF（FFFD 仍
为 0），4 fixture 全部复绿；`git diff` 因 `core.autocrlf=true`
未显示该变化，教训为字节级补丁须用 `open(...,'rb'/'wb')`。

- ADR-0796。**assets 面闭合。**
