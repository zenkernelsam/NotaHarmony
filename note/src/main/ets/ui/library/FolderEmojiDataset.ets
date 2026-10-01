// 原版 1.4.2 文件夹 emoji 选择器数据源：assets/emojis_unicode.json
// （nl4.a→rs case10：getAssets().open + kotlinx.serialization bl4 反序列化 +
// LinkedHashMap 按 ok4 类别分组）。Harmony 逐字打包同一 JSON 到 rawfile，
// 经 resourceManager.getRawFileContent + JSON.parse 等价物化。
// bl4 字段：emoji/description/category/aliases/tags（zk4 serializer：
// description 必需、aliases/tags 可空）。
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

export interface FolderEmojiInfo {
  emoji: string;
  description: string;
  category: string;
  aliases: string[];
  tags: string[];
}

// 原版 ok4 枚举序（hg2.java:87 serializer 标签序），Harmony 分区固定此序。
export const FOLDER_EMOJI_CATEGORY_NAMES: string[] = [
  'Smileys & Emotion',
  'People & Body',
  'Animals & Nature',
  'Food & Drink',
  'Activities',
  'Objects',
  'Travel & Places',
  'Symbols',
  'Flags',
];

interface RawEmojiInfo {
  emoji?: string;
  description?: string;
  category?: string;
  aliases?: string[];
  tags?: string[];
}

let sectionsCache: FolderEmojiInfo[][] | null = null;
let sectionsPromise: Promise<FolderEmojiInfo[][]> | null = null;

// rs case10 等价：读资产 → 反序列化 → 按类别分组（原版 LinkedHashMap 依
// JSON 首见序；Harmony 固定为 ok4 序，内容集相同）。
export function getFolderEmojiSections(
  context: common.UIAbilityContext): Promise<FolderEmojiInfo[][]> {
  if (sectionsCache !== null) {
    return Promise.resolve(sectionsCache);
  }
  if (sectionsPromise === null) {
    sectionsPromise = loadFolderEmojiSections(context);
  }
  return sectionsPromise;
}

async function loadFolderEmojiSections(
  context: common.UIAbilityContext): Promise<FolderEmojiInfo[][]> {
  const bytes: Uint8Array =
    await context.resourceManager.getRawFileContent('emojis_unicode.json');
  const text: string = util.TextDecoder.create('utf-8').decodeToString(bytes);
  const raw: RawEmojiInfo[] = JSON.parse(text) as RawEmojiInfo[];
  const grouped: FolderEmojiInfo[][] =
    FOLDER_EMOJI_CATEGORY_NAMES.map((_name: string) => []);
  const indexOfCategory: Map<string, number> = new Map(
    FOLDER_EMOJI_CATEGORY_NAMES.map((name: string, index: number) => [name, index]));
  for (const entry of raw) {
    if (entry.emoji === undefined || entry.description === undefined ||
        entry.category === undefined) {
      continue;
    }
    const index: number | undefined = indexOfCategory.get(entry.category);
    if (index === undefined) {
      continue;
    }
    grouped[index].push({
      emoji: entry.emoji,
      description: entry.description,
      category: entry.category,
      aliases: entry.aliases ?? [],
      tags: entry.tags ?? [],
    });
  }
  sectionsCache = grouped;
  return grouped;
}

export interface FolderEmojiSection {
  categoryIndex: number;
  items: FolderEmojiInfo[];
}

// 原版 el4.java:215-275 搜索谓词：emoji/description/aliases/tags 任一
// contains(query, ignoreCase) 命中保留；空分区整段剔除，保序带类别索引
// （el4 网格保留各分区头 ui_emojipicker__category_*）。
export function filterFolderEmojiSections(
  sections: FolderEmojiInfo[][], query: string): FolderEmojiSection[] {
  const needle: string = query.toLowerCase();
  const result: FolderEmojiSection[] = [];
  sections.forEach((section: FolderEmojiInfo[], categoryIndex: number) => {
    const filtered: FolderEmojiInfo[] = section.filter((info: FolderEmojiInfo) =>
      info.emoji.toLowerCase().includes(needle) ||
      info.description.toLowerCase().includes(needle) ||
      info.aliases.some((alias: string) => alias.toLowerCase().includes(needle)) ||
      info.tags.some((tag: string) => tag.toLowerCase().includes(needle)));
    if (filtered.length > 0) {
      result.push({ categoryIndex: categoryIndex, items: filtered });
    }
  });
  return result;
}
