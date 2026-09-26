# Phase 795 证据：原版 1.4.2 XAPK 分包与本地化面

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——XAPK 分层面收尾。
证据源：`Notability_1.4.2/…xapk`、`Notability_1.0.3/…xapk`
（ZIP 中央目录 + manifest.json + config.zh.apk 内容）、
`AppScope/app.json5`、`note/src/main/resources/`。
Replay：`docs/migration/replays/d02-original-xapk-splits-l10n.mjs`
ADR：`ADR-0739-original-xapk-splits-l10n.md`

## 1. XAPK 分包清单差

**1.0.3**（4 split）：base + config.arm64_v8a + config.en +
config.xxhdpi。

**1.4.2**（22 entry）：base + icon.png + config.arm64_v8a +
config.xxhdpi + **17 语言 split**（ar/de/en/es/fr/hi/in/
it/ja/ko/my/pt/ru/th/tr/vi/zh）+ stickers.apk。

manifest.json 关键值：vc 1040002 / "1.4.2" /
**minSdk 32 / targetSdk 36** / total 393MB；
split_configs 明确含 17 locale + stickers。

## 2. 本地化面（1.4.2 新增）

- 每个 locale split 为编译态 `resources.arsc`
  （config.zh.apk 实测 205KB）——真实翻译数据，
  非占位。
- 语言集：ar/de/es/fr/hi/in(it?)/it/ja/ko/my/pt/ru/th/
  tr/vi/zh + en（base+config.en）。
- 1.0.3 仅 en——**多语言本地化是 1.4.2 全新面**。

## 3. Harmony 侧对照

- `note/src/main/resources/`：base(en, 652 串) +
  zh_CN(649/652 串已本地化，~99.5%) + dark + rawfile。
- Harmony 端 zh_CN 已近乎全量覆盖；其余 15 语言未建
  （对应 1.0.3 基线属版本差）。

## 4. 分类结论

- 17 locale split：**版本差**（1.4.2 新本地化面）；
  Harmony 现有 zh_CN 基础，扩其余语种属 T-042 窗口
  资源工程（非代码面）。
- stickers.apk/config.xxhdpi/config.arm64_v8a：已登记
  （763/760）。
- targetSdk 36 + minSdk 32：打包策略事实登记。
