// Phase 1405 — 原版 1.4.2 笔记封面预设（iw2/ebn/d7b/cbn.f 等价）。
// 原版证据（decompiled_1.4.2）：
//   iw2：10 个 CoverPreset{F=covers/<key>.pdf, G=drawable, H=名字 res,
//     I=类目}；rs case6 逐 preset SHA-512。
//   gw2 候选：dw2=NoSelection / fw2=Preset(iw2) / ew2=Custom(jwf 上传)。
//   ebn.b：标题 ui_notecovers__title "Note cover preview" + 预览卡
//     （封面图 + noteTitle + noteDateText）+ "Presets" + g8n.a 底栏
//     Cancel/Done。
//   ebn.c(bpj, m7b{PageManager|Library|Templates}, done, jwf?种子)。
//   cbn.f 菜单行 feature_note__content_manager_add_note_cover（z5&&z4，
//     位于 create_template 与 clear_page 之间）→ l7b 封面屏幕。
//   d7b.b：selectPreset(iw2) → covers/<F>.pdf SHA-512 导入 CAS →
//     d(qab) 替换封面元素媒体；note unavailable → "Cover change skipped"。
// Harmony 落点：note_meta.cover_preset（DB v76）+ NoteCoverSheet
//   （预览卡+Presets 栅格+Cancel/Done）+ PageOverviewPanel 页菜单
//   "Add Note Cover" + 库卡片 cover_preset 命中 → covers/<key>.pdf 光栅
//   （revision 并入 |cover:key 击穿缩略图缓存）。ew2 自定义上传 fail-closed。
import { readFileSync, readdirSync } from 'node:fs';
import assert from 'node:assert';

const catalog = readFileSync('note/src/main/ets/core/model/NoteCoverCatalog.ets', 'utf8');
const sheet = readFileSync('note/src/main/ets/ui/editor/NoteCoverSheet.ets', 'utf8');
const page = readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const panel = readFileSync('note/src/main/ets/ui/editor/PageOverviewPanel.ets', 'utf8');
const library = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const repo = readFileSync('note/src/main/ets/data/NoteRepositoryImpl.ets', 'utf8');
const folder = readFileSync('note/src/main/ets/data/FolderRepositoryImpl.ets', 'utf8');
const helper = readFileSync('note/src/main/ets/data/DatabaseHelper.ets', 'utf8');
const types = readFileSync('note/src/main/ets/core/model/NoteTypes.ets', 'utf8');
const en = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── 资产：covers/ 10 个 PDF（iw2.K 全量）──
const coverFiles = readdirSync('note/src/main/resources/rawfile/covers')
  .filter((f) => f.endsWith('.pdf'));
const IW2_KEYS = ['orange', 'sage', 'stickers', 'logo-pattern', 'brown',
  'maroon', 'blue', 'yellow', 'purple-journal', 'blue-journal'];
check(coverFiles.length === 10, 'covers/ 资产 10 个');
for (const key of IW2_KEYS) {
  check(coverFiles.includes(`${key}.pdf`), `covers/${key}.pdf 落库`);
  check(catalog.includes(`key: '${key}'`), `catalog preset ${key}`);
  check(catalog.includes(`covers/${key}.pdf`), `catalog ${key} 路径`);
}
// iw2.K 枚举序保持
const order = IW2_KEYS.map((k) => catalog.indexOf(`key: '${k}'`));
check(order.every((v, i) => i === 0 || v > order[i - 1]), 'catalog iw2.K 序');

// ── 持久化：note_meta.cover_preset（DB v76）──
check(helper.includes('DB_VERSION: number = 76'), 'DB_VERSION=76');
check(helper.includes('ALTER TABLE note_meta ADD COLUMN cover_preset'),
  'note_meta.cover_preset 迁移');
check(helper.includes('cover_preset TEXT DEFAULT NULL'), 'base DDL cover_preset');
check(types.includes('coverPreset'), 'NoteMeta.coverPreset');
check(repo.includes('cover_preset') && repo.includes('setNoteCoverPreset'),
  'repo cover_preset 读写');
check(repo.includes("'updated_at': Date.now()"), '封面变更 bump updated_at');
check(folder.includes('cover_preset'), 'FolderRepositoryImpl 投影补齐');

// ── 选择器（ebn.b）：预览卡 + Presets + Cancel/Done ──
check(sheet.includes('note_cover_title') && sheet.includes('note_cover_presets'),
  'sheet 标题/Presets 区');
check(sheet.includes('app.string.cancel') && sheet.includes('app.string.done'),
  'Cancel/Done 底栏');
check(sheet.includes('selectedKey === preset.key'), '选中态徽记');
check(sheet.includes('this.selectedKey !== \'\'') && sheet.includes('enabled('),
  'Done 需候选');
check(sheet.includes('loadNoteCoverThumb'), 'preset PDF 光栅缩略图');
check(sheet.includes('noteTitle') && sheet.includes('noteCreatedAt'),
  '预览卡标题+日期（i7b.b/c）');
check(sheet.includes('currentPresetKey'), 'iw2 键预选种子');

// ── 入口：cbn.f 页菜单行 ──
check(panel.includes('add_note_cover') && panel.includes("'add_cover'"),
  '页菜单 Add Note Cover 行');
check(panel.indexOf('add_note_cover') < panel.indexOf('menuicon_clear_page'),
  '行序：add_cover 在 clear_page 之前');
check(page.includes("'add_cover'") && page.includes('showNoteCoverSheet = true'),
  'NotePage add_cover → 打开 sheet');
check(page.includes('buildNoteCoverSheet') && page.includes('bindSheet(this.showNoteCoverSheet'),
  'NotePage bindSheet');
check(page.includes('setNoteCoverPreset') && page.includes('noteCoverPresetKey = presetKey'),
  'apply → 持久化 + 状态回写');
check(page.includes('noteCoverPresetKey = note.coverPreset'), '加载期种子');

// ── 库卡片渲染 ──
check(library.includes('coverByNoteId') && library.includes('findNoteCoverPreset'),
  '库卡片封面查询');
check(library.includes('|cover:'), 'revision 并入封面键击穿缓存');
check(library.includes('loadNoteCoverThumb'), 'covers PDF 光栅');
check(library.includes('renderThumbnail'), '无封面回退常规缩略图');

// ── 字符串 ──
check(en.includes('"note_cover_title"') && en.includes('"Note cover preview"') &&
  en.includes('"add_note_cover"') && en.includes('"Add Note Cover"'),
  'en 标题/入口');
check(zh.includes('"note_cover_title"') && zh.includes('"笔记封面预览"') &&
  zh.includes('"add_note_cover"') && zh.includes('"添加笔记封面"'),
  'zh 标题/入口');
for (const key of IW2_KEYS) {
  const resKey = `note_cover_preset_${key.replace(/-/g, '_')}`;
  check(en.includes(`"${resKey}"`) && zh.includes(`"${resKey}"`),
    `preset 串 ${resKey}`);
}

console.log(`d02-original-note-cover-presets OK — ${n} checks`);
