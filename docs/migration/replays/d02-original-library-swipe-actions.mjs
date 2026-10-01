// Phase 1410 — 库 list 行 + 侧栏文件夹滑动操作（wbn/d2n 等价，1.4.2 证据）。
//
// 原版证据（decompiled_1.4.2）：
//   wbn.c：list 行左滑（-f 拖距）尾缘揭示操作条——行内 [favorite][weight
//     spacer][delete]，fR≥f3*0.6 时渲染 cc3.l 图标钮；
//     favorite 图标按态切 ui_designsystem__(un)favorite_outline，
//     cd = (un)favorite_note_swipe_action "…note \"%1$s\""，
//     回调 ucb(F=1) = 未落定→invoke、已落定→cgh.a() 归位；
//     delete 图标 = ui_designsystem__trash，cd = delete_note_swipe_action，
//     回调 wpa(rgaVar,18) = 置删除确认框态（非直删）。
//   d2n.c：侧栏文件夹行同构滑动——仅 trash + sidebar_delete_folder_
//     swipe_action "Delete folder \"%1$s\""，回调起 kcj 删除确认框。
// Harmony 落点：LibraryPage.ets —— NoteListRow ListItem
//   .swipeAction{end}(多选态 {} 禁滑)，NoteSwipeActions =
//   Row{favorite(accent bg)/delete(danger bg) 56vp 钮}；
//   FolderNavigationList ListItem .swipeAction{end} →
//   FolderSwipeAction = 48vp trash 钮 → confirmDeleteFolder。

import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const lib = readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const glyphs = readFileSync('note/src/main/ets/ui/components/ToolGlyphs.ets', 'utf8');
const baseStr = readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStr = readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// ── 字符串资源：swipe-action 带标题 cd（en + zh）──
for (const [key, en, zh] of [
  ['favorite_note_swipe_action', 'Favorite note \\"%1$s\\"', '收藏笔记“%1$s”'],
  ['unfavorite_note_swipe_action', 'Unfavorite note \\"%1$s\\"', '取消收藏笔记“%1$s”'],
  ['delete_note_swipe_action', 'Delete note \\"%1$s\\"', '删除笔记“%1$s”'],
  ['delete_folder_swipe_action', 'Delete folder \\"%1$s\\"', '删除文件夹“%1$s”'],
]) {
  check(baseStr.includes(`"name": "${key}"`), `base 串 ${key}`);
  check(zhStr.includes(`"name": "${key}"`), `zh 串 ${key}`);
  check(zhStr.includes(zh), `zh 串 ${key} 文案`);
}

// ── ToolGlyphs：favorite_outline / unfavorite_outline / trash ──
check(/'favorite_outline': \{ f: ``, o: `M12\.691,19\.969/.test(glyphs),
  'favorite_outline 星形描边（ui_designsystem__favorite_outline）');
check(/'unfavorite_outline': \{ f: ``, o: `M8\.85,6\.01L10\.67,2\.33/.test(glyphs) &&
  /unfavorite_outline[\s\S]*?M2\.5,2\.5L21\.5,21\.5/.test(glyphs),
  'unfavorite_outline 星形残段+斜杠');
check(/'trash': \{ f: ``, o: `M17\.525,22\.66H6\.845/.test(glyphs) &&
  /'trash'[\s\S]*?M12\.185,9\.95V19\.56/.test(glyphs),
  'trash 桶身+盖+内线（ui_designsystem__trash）');

// ── NoteListRow：list 态 ListItem 挂 swipeAction end，多选禁滑 ──
check(/this\.NoteListRow\(note\)\s*\}[\s\S]*?\.swipeAction\(this\.isMultiSelecting \? \{\}/.test(lib),
  'list 行 swipeAction + 多选禁滑');
check(/\.swipeAction\(this\.isMultiSelecting \? \{\} : \{[\s\S]*?end: \(\) => \{ this\.NoteSwipeActions\(note\) \}/.test(lib),
  'end builder → NoteSwipeActions(note)');
check(/edgeEffect: SwipeEdgeEffect\.Spring/.test(lib), 'Spring 回弹边效');

// ── NoteSwipeActions：favorite(accent)+delete(danger) 双钮，标题 cd ──
check(/NoteSwipeActions\(note: NoteMeta\)/.test(lib), 'NoteSwipeActions builder');
check(/glyph: note\.favorite \? 'unfavorite_outline' : 'favorite_outline'/.test(lib),
  'favorite 图标按态切换（wbn z 分支）');
check(/\$r\('app\.string\.unfavorite_note_swipe_action', this\.noteDisplayTitle\(note\)\)[\s\S]*?:[\s\S]*?\$r\('app\.string\.favorite_note_swipe_action', this\.noteDisplayTitle\(note\)\)/.test(lib),
  'favorite 钮带标题 cd 双态');
check(/\$r\('app\.string\.delete_note_swipe_action', this\.noteDisplayTitle\(note\)\)/.test(lib),
  'delete 钮带标题 cd');
check(/glyph: 'trash'/.test(lib), 'delete 钮 trash 图标');
// 顺序：favorite 钮先于 delete 钮（原版 [favorite][spacer][delete] 内→外）
const favIdx = lib.indexOf('favorite_note_swipe_action');
const delIdx = lib.indexOf('delete_note_swipe_action');
check(favIdx > 0 && delIdx > favIdx, 'favorite 内排 / delete 边缘序');
// 行为接线：favorite → toggleNoteFavorite（ucb.invoke 等价），
// delete → confirmDelete（wpa 置态 → 确认框等价，非直删）
check(/favorite_note_swipe_action[\s\S]*?this\.toggleNoteFavorite\(note\)/.test(lib),
  'favorite 钮 → toggleNoteFavorite');
check(/delete_note_swipe_action[\s\S]*?this\.confirmDelete\(note\)/.test(lib),
  'delete 钮 → confirmDelete（确认框）');
check(/backgroundColor\(this\.resolveTokens\(\)\.accent\)/.test(lib) &&
  /backgroundColor\(this\.resolveTokens\(\)\.danger\)/.test(lib),
  'accent/danger 双底色');

// ── FolderNavigationList：侧栏文件夹行 swipeAction end = delete ──
check(/this\.FolderNavigationRow\(item\)[\s\S]*?\.swipeAction\(\{\s*end: \(\) => \{ this\.FolderSwipeAction\(item\) \}/.test(lib),
  '文件夹行 swipeAction end → FolderSwipeAction');
check(/FolderSwipeAction\(item: FolderListItem\)/.test(lib), 'FolderSwipeAction builder');
check(/\$r\('app\.string\.delete_folder_swipe_action', item\.folder\.name\)/.test(lib),
  '文件夹 delete 钮带标题 cd');
check(/FolderSwipeAction[\s\S]*?this\.confirmDeleteFolder\(item\.folder\)/.test(lib),
  '文件夹 delete → confirmDeleteFolder');

console.log(`d02-original-library-swipe-actions: ${n} checks OK`);
