// Phase 1377 — page-manager page-actions menu items carry their original
// n9j icons (MenuElement.icon -> media SVG replicas).
//
// n9j.java content-manager page menu: each row is apb.f(icon=h1a,label).
//   add_page=__add_page  cut=__cut  copy=__copy  paste=__paste_content_manager
//   duplicate=__duplicate  rotate_page=__rotate_page  clear_page=__clear_page
//   delete=ue4.z()=__trash ; bookmark via bookmark_tall_fill (toolbar glyph).
// move_earlier/move_later are Harmony-adaptation reorder controls -> no icon.
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const bar = readFileSync(join(root, 'note/src/main/ets/ui/editor/PageManagerBar.ets'), 'utf8');
const seg = bar.slice(bar.indexOf('buildPageMenu(): MenuElement[]'),
  bar.indexOf('return items;'));

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

const ITEM = [
  ['bookmark_page', 'app.media.menuicon_bookmark'],
  ['cut_page', 'app.media.selmenu_cut'],
  ['copy_page', 'app.media.selmenu_copy'],
  ['duplicate_page', 'app.media.selmenu_duplicate'],
  ['rotate_page', 'app.media.menuicon_rotate_page'],
  ['clear_page', 'app.media.menuicon_clear_page'],
  ['delete_page', 'app.media.selmenu_delete'],
];
ITEM.forEach(([str, icon]) => {
  eq(seg.includes(`value: $r('app.string.${str}'), icon: $r('${icon}')`),
     `page menu '${str}' icon ${icon.split('.').pop()}`);
});
// conditional paste between copy and duplicate
eq(seg.includes(`items.splice(5, 0, { value: $r('app.string.paste_page'), icon: $r('app.media.selmenu_paste')`),
  'paste_page (spliced) uses selmenu_paste');
// Harmony-adaptation reorder controls carry no icon.
eq(!/move_page_earlier'\),\s*icon/.test(seg) && !/move_page_later'\),\s*icon/.test(seg),
  'move_earlier/move_later remain iconless (Harmony adaptation)');

// --- media resources exist ---
['menuicon_bookmark','menuicon_rotate_page','menuicon_clear_page',
 'selmenu_cut','selmenu_copy','selmenu_paste','selmenu_duplicate','selmenu_delete']
  .forEach(m => eq(existsSync(join(root, `note/src/main/resources/base/media/${m}.svg`)),
     `media ${m}.svg present`));

// --- behavior/ordering guards unchanged ---
eq(seg.includes('this.onToggleBookmark()') && seg.includes('this.onRotatePage()') &&
   seg.includes('this.photoImportLeaseActive') && seg.includes('items.splice(5, 0'),
  'menu actions/lease guards/paste splice unchanged');

console.log(`\npage-actions-menu-icons: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { console.log('FAILED:', fail); process.exit(1); }
