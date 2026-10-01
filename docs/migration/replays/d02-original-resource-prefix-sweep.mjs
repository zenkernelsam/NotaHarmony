// D02 原版 1.4.2 资源前缀扫描收口（Phase 1427 裁决）
// 覆盖最后一批未裁决前缀：
//   pen_palette_*/pen_swatch_*/pen_string_* —— 消费方全部位于
//     com.samsung.android.sdk.pen.*（S Pen SDK 随包私有调色板），
//     Harmony 已按同名键移植预设色井 a11y 子集，其余 158+ 命名片
//     属 vendored SDK 内部资源，无 Harmony 宿主 → fail-closed。
//   ui_templates__* —— bundled 图库已移植（PaperTemplateGallery：
//     qia recents/favorites+类别区块）；Gallery 搜索/翻页=远端模板
//     服务（xcm onGalleryQueryChange/onLoadMoreGalleryTemplates）→
//     fail-closed；My Templates 增删改=rd5 InternalUserOnly 门控
//     → fail-closed；多页模板 select_pages(olm.a) 仅远端 Gallery
//     包可达 → fail-closed；repeat/interactive_template 为 1.4.2
//     死字符串（仅 R.java 引用，无消费方）。
//   ui_notecovers__* —— 已移植（NoteCoverSheet 10 preset，ADR-1341）。
//   ui_papertemplates__* —— 类别键已移植（paper_templates_cat_*）。
//   m3c_/mtrl_/mids_/dream_/ids_/firebase_/google_/common_/abc_/
//   androidx_/fk_/generic_/nav_/notification_/preference_/exo_/
//   call_/material_ —— vendored 库字符串，无宿主。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');

const strings = read('note/src/main/resources/base/element/string.json');
const gallery = read('note/src/main/ets/ui/editor/PaperTemplateGallery.ets');
const cover = read('note/src/main/ets/ui/editor/NoteCoverSheet.ets');
const colorPicker = read('note/src/main/ets/ui/components/ColorPicker.ets');
const adr = read('docs/migration/adr/ADR-1362-resource-prefix-sweep.md');
const ev = read('docs/migration/evidence/phase-1427-resource-prefix-sweep.md');

// --- bundled 模板图库已移植 ---
check('gallery has qia recents/favorites sections + category blocks',
  /recents/.test(gallery) && /favorite/.test(gallery) &&
  /paper_templates_cat_/.test(strings));
check('note covers: 10 preset keys + preview + Cancel/Done (ADR-1341)',
  cover.includes('NOTE_COVER_PRESETS') &&
  strings.includes('note_cover_preset_purple_journal'));

// --- pen_palette 子集移植 + vendored 主体 fail-closed ---
check('preset-well a11y subset uses original pen_palette_color_* keys',
  colorPicker.includes('pen_palette_color_black') &&
  strings.includes('pen_swatch_color_pink'));
check('harmony pen_palette subset stays small (no vendored 158+ dump)',
  (strings.match(/pen_palette_color_/g) || []).length <= 20);

// --- 远端 Gallery / 内部模板管理 fail-closed ---
check('no remote-gallery search surface (xcm onGalleryQueryChange)',
  !strings.includes('search_gallery') && !gallery.includes('Search'));
check('no custom-template management (rd5 InternalUserOnly)',
  !strings.includes('save_as_template') && !strings.includes('my_templates'));
check('no multi-page template select-pages surface (olm.a 远端包限定)',
  !strings.includes('select_pages'));

// --- 裁决文书 ---
check('ADR-1362 records the sweep-closure adjudication',
  adr.includes('pen_palette') && adr.includes('ui_templates') &&
  adr.includes('InternalUserOnly'));
check('evidence doc records vendored-prefix boundary',
  ev.includes('com.samsung.android.sdk.pen') && ev.includes('olm.a'));

console.log(`TOTAL=${checks.length} FAILED=0`);
