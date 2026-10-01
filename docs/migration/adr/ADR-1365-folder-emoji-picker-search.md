# ADR-1365：文件夹 emoji 选择器全数据集 + 搜索补齐

- 状态：Accepted
- 关联：ADR-1362（strings.xml 前缀扫描）、ADR-1341（封面图库资产
  逐字打包先例）、evidence `phase-1430-folder-emoji-picker.md`、
  fixture `d02-original-folder-emoji-picker.mjs`

## 背景

既有实现已含 `ok4` 九类 + 类别图标条 + 每类 ~20 枚策划子集；
原版 `el4` 选择器实际为**全量数据集 + 顶部搜索框**：

- emoji 本体来自 `assets/emojis_unicode.json`（424KB/1913 条，
  `nl4`→`rs` case10 资产加载，`bl4`{emoji,description,category,
  aliases,tags} 按 `ok4` 分组）；
- 搜索框 `e9n.a`（search_placeholder/clear_search），谓词
  `el4.java:215-275` = emoji/description/aliases/tags 任一
  `contains(q, ignoreCase)`，空分区剔除，空图 → `no_results`。

Harmony 侧缺搜索面与全量数据集 —— 真实可移植缺口（资产随包，
无后端依赖）。

## 决定

1. **逐字打包** `emojis_unicode.json` → `rawfile/`（同 covers/
   papertemplates/planners 资产等价先例）。
2. `FolderEmojiDataset.ets`：`getFolderEmojiSections`（
   `getRawFileContent` + utf-8 TextDecoder + JSON.parse，`ok4`
   序九分区，模块缓存）+ `filterFolderEmojiSections`（谓词逐字
   等价，剔空分区、保类别索引）。
3. `NameDialog` emoji 页签：顶部搜索框 + 非空 `×` 清除钮；
   查询非空 → 分区结果（类别头 + 网格）/`no_results` 空态；
   查询为空 → 图标条 + 当前分区网格（全集，加载前策划子集占位）。
4. 新键 `emoji_search_placeholder`/`emoji_clear_search`/
   `emoji_no_results` en 逐字 + zh 补写。

## 呈现差异（登记）

- 类别图标条：原版为分区网格滚动锚点（`vr9` 头索引表）；
  Harmony 维持已交付的切分区语义——同类别/同图标/同数据，
  交互等价、呈现简化，不再追加滚动定位。
- 单元格尺寸：原版 48dp 网格格 vs Harmony 既有紧凑格
  （对话框内高度约束），属呈现层差异。
- 原版分区序按 JSON 首见序（Travel 在 Activities 前）；
  Harmony 固定 `ok4` 枚举序——浏览态与图标条一致，差异无感。

## 后果

- 文件夹 emoji 选择面达到原版功能对等：1913 枚全集 +
  跨字段搜索 + 空态。
- 不引入 Harmony 系统 emoji 面板依赖；离线可用。
