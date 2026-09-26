# Phase 792 证据：原版 1.4.2 内置拼写检查 + planner 资产

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——assets/ 目录收尾。
证据源：`decompiled_1.4.2/resources/assets/`、`sources/defpackage/{bc1,ac1,fal,cji,rs}.java`、strings.xml。
Replay：`docs/migration/replays/d02-original-spellcheck-planners.mjs`
ADR：`ADR-0736-original-spellcheck-planners.md`

## 1. assets/ 顶层差

| 目录 | 1.0.3 | 1.4.2 | 判定 |
|------|-------|-------|------|
| brushpacks/ | 无 | 5 包 | 762 已登记 |
| covers/ | 无 | 10 PDF | 763 已登记 |
| papertemplates/ | 无 | 35 包 | 761 已登记 |
| planners/ | 无 | 2 PDF | 本阶段 |
| spellcheck/ | 无 | en_words.dat | 本阶段 |
| conf-lite/ | 有 | 无 | MyScript lite 移除（760） |
| conf/en_US.conf | 有 | 有（内容变更） | MyScript 配置更新 |

其余（ConversionRates/PublicSuffixDatabase/dexopt/
emojis_unicode/glmath/mlkit-google-ocr-models/resources）
两版一致。

## 2. planners/ —— 学术计划本成品 PDF

- `academic_planner_2026_2027-monday_start.pdf`
- `academic_planner_2026_2027-sunday_start.pdf`

与 782 的 `ui_planners__`（周起始切换）+ 791 的四张
planner 封面 webp 构成完整闭环：选起始日 → 对应 PDF
作笔记底。版本差登记。

## 3. spellcheck/ —— 内置英文词库拼写检查（1.4.2 全新）

- `en_words.dat`：gzip 压缩英文词表，321KB（解压
  ~1.2MB/126,036 词条，含 0th 序数与 déshabillé
  外来词），`rs.java` case 3 以 GZIPInputStream 装入
  `HashSet(150000)` 容量集合。
- `bc1.java`：词典加载器/检查器——`volatile Set` +
  `BreakIterator`/`Locale` 分词；`a(List, …)` 返回
  逐词拼写状态；加载失败 fail-soft 回退 `rm4.F`
  （日志域 `zg9.TEXT`）。
- `fal.b(bc1, words, …)`：批量拼写 API——合并既有
  已知词表（linkedHashMap）与 bc1 词典判定，产出
  word→status 映射。
- `cji`（rz5 Flow 管线）：`o0` 字段持 bc1，将拼写
  结果与文本内容合并——文本编辑器的拼写装饰管线。
- 设置开关（1.4.2 新增，1.0.3 无）：
  `feature_settings__check_spelling` +
  `check_spelling_description`。

## 4. Harmony 侧对照

Harmony 文本编辑无拼写检查面——纯本地功能（词库+分词
+集合判定），技术上可移植；属 1.4.2 版本差，登记待
T-042 窗口决策。

## 5. 分类结论

- 拼写检查：**纯本地**、版本差新功能。
- planner PDF：**本地资产**、随 782 簇。
- conf-lite 移除：MyScript 远端化佐证（760/768）。
- assets/ 面至此全量归属完毕。
