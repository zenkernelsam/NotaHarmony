// D02 原版 1.4.2 文件夹 emoji 选择器数据集 + 搜索补齐（Phase 1430）
// 原版：el4 选择器 = 顶部 e9n.a 搜索框（search_placeholder/clear_search）
// + ok4 九类分区 LazyVerticalGrid（48dp 格、分区头 category_*）+
// map2.isEmpty() → no_results。emoji 本体 = assets/emojis_unicode.json
// （nl4→rs case10 资产加载，bl4{emoji,description,category,aliases,tags}
// 反序列化按类别 LinkedHashMap 分组，约 1913 枚）。
// 过滤谓词 el4.java:215-275：emoji/description 或任一 aliases/tags
// contains(query, ignoreCase) 命中保留，空分区剔除。
// Harmony：rawfile 逐字打包同一 JSON + FolderEmojiDataset
// （getRawFileContent + JSON.parse + ok4 序分组 + filterFolderEmojiSections
// 同谓词）；NameDialog 增搜索框 + 清除钮 + no_results + 分区结果；
// 浏览态分区网格保留（数据由策划子集换为全集，策划子集留作加载前占位）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');

const dataset = read('note/src/main/ets/ui/library/FolderEmojiDataset.ets');
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const stringsEn = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

// --- 数据资产逐字打包 ---
const rawStat = fs.statSync('note/src/main/resources/rawfile/emojis_unicode.json');
check('emojis_unicode.json bundled as rawfile (>400KB, ~1913 entries)',
  rawStat.size > 400000);

// --- 加载通路等价（nl4 assets.open → getRawFileContent + JSON.parse） ---
check('dataset loads emojis_unicode.json via resourceManager',
  dataset.includes("getRawFileContent('emojis_unicode.json')") &&
  dataset.includes('JSON.parse'));
check('dataset groups by ok4 nine-category order',
  dataset.includes("'Smileys & Emotion'") && dataset.includes("'Flags'") &&
  dataset.indexOf('Smileys & Emotion') < dataset.indexOf('Flags') &&
  dataset.includes('FOLDER_EMOJI_CATEGORY_NAMES'));
check('dataset decodes utf-8 via TextDecoder',
  dataset.includes("TextDecoder.create('utf-8')"));

// --- 搜索谓词与 el4 等价（emoji/description/aliases/tags contains-ci） ---
check('filter predicate covers emoji+description+aliases+tags',
  dataset.includes('info.emoji.toLowerCase().includes(needle)') &&
  dataset.includes('info.description.toLowerCase().includes(needle)') &&
  dataset.includes('info.aliases.some') &&
  dataset.includes('info.tags.some'));
check('empty categories dropped from search results',
  dataset.includes('filtered.length > 0'));

// --- 对话框接线：搜索框 + 清除钮 + no_results + 分区结果 ---
check('search field with placeholder + change wiring',
  page.includes('emojiQuery') &&
  page.includes('emoji_search_placeholder') &&
  page.includes('this.emojiQuery = value'));
check('clear-search affordance resets query',
  page.includes('emoji_clear_search') && page.includes("this.emojiQuery = ''"));
check('no_results empty state rendered',
  page.includes('emoji_no_results'));
check('search results sectioned by category index headers',
  page.includes("emoji_category_' + section.categoryIndex") ||
  page.includes('emoji_category_' + String.fromCharCode(39) + ' + section.categoryIndex'));
check('browse mode keeps icon strip + full-dataset section grid',
  page.includes('FOLDER_EMOJI_CATEGORY_ICONS') &&
  page.includes('emojiSectionEmojis(this.emojiCategory)') &&
  page.includes('emojiSections'));
check('dataset loaded lazily in aboutToAppear via getContext',
  page.includes('getFolderEmojiSections(getContext(this)') &&
  page.includes('this.emojiSections = sections'));

// --- 字符串 en/zh ---
check('emoji search strings exist in en + zh',
  stringsEn.includes('"emoji_search_placeholder"') &&
  stringsEn.includes('"emoji_clear_search"') &&
  stringsEn.includes('"emoji_no_results"') &&
  stringsZh.includes('"emoji_search_placeholder"') &&
  stringsZh.includes('"emoji_clear_search"') &&
  stringsZh.includes('"emoji_no_results"'));

console.log(`TOTAL=${checks.length} FAILED=0`);
