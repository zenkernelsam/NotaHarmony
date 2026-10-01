# Phase 1430 证据：文件夹 emoji 选择器数据集 + 搜索补齐

日期：2026-08-09
关联：ADR-1365；fixture `docs/migration/replays/d02-original-folder-emoji-picker.mjs`（13 项）。

## 原版证据链

### 数据资产

`rs.java` case10（`nl4.a` 挂起函数内）：

```java
InputStream inputStreamOpen3 = nl4Var.a.getAssets().open("emojis_unicode.json");
BufferedReader bufferedReader = new BufferedReader(
    new InputStreamReader(inputStreamOpen3, fs1.a), SemanticState.Multiline);
String strK = dbj.K(bufferedReader);
Iterable iterable = (Iterable) nl4Var.b.a(
    new aa0(bl4.Companion.serializer()), strK);
LinkedHashMap linkedHashMap2 = new LinkedHashMap();
for (Object obj3 : iterable) {
    ok4 ok4Var = ((bl4) obj3).c;
    ... // 按类别 LinkedHashMap 分组
}
```

- `bl4`（EmojiInfo）：`emoji`/`description`/`category`/`aliases`/`tags`
  （`zk4` serializer：`description` 必需，`aliases`/`tags` 可空，
  `bl4.java:64` toString 直证字段）。
- `ok4` 九类枚举 + `hg2.java:87` serializer 标签序：Smileys & Emotion /
  People & Body / Animals & Nature / Food & Drink / Activities /
  Objects / Travel & Places / Symbols / Flags。
- `emojis_unicode.json`：424,481 B、1913 条、9 类，逐字打包进 Harmony
  `rawfile/`（既有资产等价先例：covers/planners/papertemplates）。

### 选择器结构（el4.java）

- `e9n.a(str, nf3 回写, search_placeholder, clear_search, ...)` ——
  顶部搜索框，非空出清除钮。
- `map2` = 过滤后分区图；`map2.isEmpty()` → `no_results` 文本
  （k62.b 正文）。
- `rym.b(zn6(48dp), ...)` LazyVerticalGrid 分区网格 + 分区头
  （`vr9` 头索引表 `size += list.size() + 1`）。
- `he.java:306-377`：类别图标条（emojis_smiley/pawprint/food/
  basketball/lightbulb/car/numbers/flag）。
- 宿主：`po2` case3 → `el4.b` 对话框；`l8n` 对话框分派链可达。

### 搜索谓词（el4.java:215-275）

```java
if (r0h.D0(bl4Var.a /*emoji*/, string, true)
    || r0h.D0(bl4Var.b /*description*/, string, true)) { add }
else 遍历 bl4Var.d /*aliases*/ D0(alias, q, true) 命中 → add
else 遍历 bl4Var.e /*tags*/    D0(tag,   q, true) 命中 → add
// 过滤后空分区整段剔除
```

`r0h.D0(s, q, true)` = `String.contains(q, ignoreCase=true)`。

## Harmony 落地

- `rawfile/emojis_unicode.json`：原版资产逐字拷贝。
- `FolderEmojiDataset.ets`：`getFolderEmojiSections`（rawfile +
  TextDecoder utf-8 + JSON.parse → `ok4` 序九分区分组，模块级缓存）；
  `filterFolderEmojiSections` 逐字复刻谓词（emoji/description/
  aliases/tags `toLowerCase().includes`），剔空分区，保类别索引。
- `NameDialog`（LibraryPage）：emoji 页签顶部增搜索框
  （`emoji_search_placeholder` + 非空 `×` 清除钮 `emoji_clear_search`）；
  查询非空 → `emojiSearchResults()` 分区结果（类别头 + 7 列网格），
  空结果 → `emoji_no_results` 居中正文；查询为空 → 原图标条 +
  分区网格（数据换全集，加载前用 `FOLDER_EMOJI_FALLBACK_CATEGORIES`
  策划子集占位）。
- 切回 Color 页签同时清 `emojiQuery`（装饰互斥同 wm2 语义）。
- 新键 `emoji_search_placeholder`/`emoji_clear_search`/`emoji_no_results`
  en+zh（原版串值逐字 + zh 补写）。

## 呈现差异登记（ADR-1365）

- 原版类别图标条是分区网格的滚动锚点（`map3` 分区起始索引）；
  Harmony 保持已交付的"切分区"语义（同类别、同图标、同数据），
  图标条点击=切分区而非滚动定位——交互等价、呈现简化。
- 原版搜索态网格保留分区头；Harmony 搜索态同样渲染类别头文本
  （emoji_category_N），结构一致。
- 原版单元格 48dp；Harmony 继承既有紧凑单元格（~26dp），对话框
  内尺寸约束不同，登记为呈现层差异。
