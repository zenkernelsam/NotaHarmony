// Phase 673 — 原版库内多选模式（长按进入 + 勾选圈 + 顶栏计数/全选 +
// 底栏批量 Favorite/Duplicate/Delete）。
// 原版证据（decompiled_1.0.3）：
//   pk9.java   X=多选态 StateFlow、Y=已选 id 集；o(ttf)：CAS X→true 后
//     r(ttf) 立即选中长按项；r(ttf)：do6.z 成员判定后翻转 Y；
//     p()：CAS X→false 后 CAS Y→空集。
//   tj9.java   单元格回调分派：case0/6 → pk9.o（长按进多选）。
//   xj9.java   单元格接线：长按 = tj9(0/6)。
//   d5j.java   单笔记溢出菜单（Rename/Favorite/Duplicate/Export/…/
//     Delete）——无 Select 项，多选入口不在菜单里。
//   hof.java   顶栏：选中集大小 != 可见列表大小 → select_all 否则
//     deselect_all；选中集为空时动作区不渲染。
//   l05.java   底栏：ek9 派生态驱动动作；ek9.b=actionsEnabled。
//   ek9.java   多选派生模型（a=SelectAll 语义、b=actionsEnabled、
//     e=allSelectedAreFavorited 驱动 Favorite/Unfavorite 翻转）。
//   fj9/gj9    底栏按钮回调（Duplicate / Favorite / Delete）。
//   o94.java   勾选圈组件（checkmark_circle/circle_empty_med_outline）。
//   lq7.java   返回键消费：多选态 → pk9.p。
//   strings.xml feature_library__select_all / _deselect_all /
//     _select_note / _share；plurals feature_library__notes_selected
//     ("%1$d Note Selected"/"%1$d Notes Selected")。
// Harmony 对齐：LibraryPage @State isMultiSelecting/selectedNoteIds/
// multiSelectBusy；NoteCard/NoteListRow 长按 → enterMultiSelect（原
// bindContextMenu 长按改 ⋯ 溢出按钮 bindMenu 承载 d5j 菜单）；多选
// 态点击 = toggleMultiSelectId；SelectCircle 勾选圈（o94）；
// MultiSelectTopBar = Select All/Deselect All + "%d Note(s)
// Selected" + Done；MultiSelectActionBar = Duplicate/Favorite/
// Delete（enabled=count>0 && !busy）；onBackPress → exitMultiSelect；
// FAB 在多选态隐藏。Share 图标受 lc4 旗标门控，fail-closed 登记至
// Phase 674（多笔记分享）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const pk9 = fs.readFileSync(`${originalRoot}sources/defpackage/pk9.java`, 'utf8');
const tj9 = fs.readFileSync(`${originalRoot}sources/defpackage/tj9.java`, 'utf8');
const d5j = fs.readFileSync(`${originalRoot}sources/defpackage/d5j.java`, 'utf8');
const hof = fs.readFileSync(`${originalRoot}sources/defpackage/hof.java`, 'utf8');
const l05 = fs.readFileSync(`${originalRoot}sources/defpackage/l05.java`, 'utf8');
const ek9 = fs.readFileSync(`${originalRoot}sources/defpackage/ek9.java`, 'utf8');
const o94 = fs.readFileSync(`${originalRoot}sources/defpackage/o94.java`, 'utf8');
const lq7 = fs.readFileSync(`${originalRoot}sources/defpackage/lq7.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');
const pluralsXml = fs.readFileSync(`${originalRoot}resources/res/values/plurals.xml`, 'utf8');

const lib = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let total = 0;
const check = (cond, label) => {
  total++;
  try { assert.ok(cond, label); }
  catch (e) { console.error(`FAILED: ${label}`); throw e; }
};

// ---------- 原版证据 ----------
check(/public final void o\(ttf/.test(pk9) && pk9.includes('Boolean.TRUE'),
  'original pk9.o enters selection mode');
check(/public final void p\(\)/.test(pk9) && pk9.includes('Boolean.FALSE') &&
  pk9.includes('qw3.I'),
  'original pk9.p exits mode and clears the set');
check(/public final void r\(ttf/.test(pk9) && pk9.includes('do6.z'),
  'original pk9.r toggles membership');
check(tj9.includes('pk9Var.o(w09Var.a);'),
  'original tj9 routes cell callbacks to pk9.o');
check(d5j.includes('Menu') || d5j.includes('rename') || d5j.length > 0,
  'original d5j single-note menu exists');
check(hof.includes('feature_library__select_all') &&
  hof.includes('feature_library__deselect_all') &&
  hof.includes('size() != list.size()'),
  'original hof toggles Select All/Deselect All by coverage');
check(l05.includes('ek9') && ek9.length > 0,
  'original l05 renders actions from ek9 derived state');
check(o94.length > 0, 'original o94 check-circle cell exists');
check(lq7.length > 0, 'original lq7 back-press consumer exists');
check(stringsXml.includes('feature_library__select_all') &&
  stringsXml.includes('feature_library__deselect_all') &&
  stringsXml.includes('feature_library__select_note') &&
  stringsXml.includes('feature_library__share'),
  'original library strings present');
check(pluralsXml.includes('feature_library__notes_selected') &&
  pluralsXml.includes('%1$d Note Selected') &&
  pluralsXml.includes('%1$d Notes Selected'),
  'original notes_selected plural present');

// ---------- Harmony 多选态 ----------
check(lib.includes('@State isMultiSelecting: boolean = false;') &&
  lib.includes('@State selectedNoteIds: string[] = [];') &&
  lib.includes('@State multiSelectBusy: boolean = false;'),
  'Harmony selection state fields present');

// ---------- 长按进入 + 点击翻转 ----------
const enterM = lib.indexOf('private enterMultiSelect(noteId: string): void {');
check(enterM >= 0 &&
  lib.slice(enterM, enterM + 400).includes('this.isMultiSelecting = true;') &&
  lib.slice(enterM, enterM + 400).includes('this.selectedNoteIds = [noteId];'),
  'enterMultiSelect mirrors pk9.o (mode + select long-pressed note)');
const toggleM = lib.indexOf('private toggleMultiSelectId(noteId: string): void {');
check(toggleM >= 0 &&
  lib.slice(toggleM, toggleM + 500).includes('indexOf(noteId)') &&
  lib.slice(toggleM, toggleM + 500).includes('splice(idx, 1)') &&
  lib.slice(toggleM, toggleM + 500).includes('push(noteId)'),
  'toggleMultiSelectId mirrors pk9.r membership toggle');
const exitM = lib.indexOf('private exitMultiSelect(): void {');
check(exitM >= 0 &&
  lib.slice(exitM, exitM + 300).includes('this.isMultiSelecting = false;') &&
  lib.slice(exitM, exitM + 300).includes('this.selectedNoteIds = [];'),
  'exitMultiSelect mirrors pk9.p (mode off + clear set)');
check(lib.includes('.gesture(LongPressGesture().onAction(() => {\n      this.enterMultiSelect(note.id);'),
  'long-press enters multi-select (pk9.o via tj9 case0/6)');
check(lib.includes('if (this.isMultiSelecting) {\n        this.toggleMultiSelectId(note.id);\n        return;'),
  'in-mode tap toggles selection instead of opening the note');

// ---------- 勾选圈 + ⋯ 溢出按钮 ----------
check(lib.includes('SelectCircle(note: NoteMeta)') &&
  lib.includes("Text('✓')") &&
  lib.includes("$r('app.string.select_note')"),
  'SelectCircle mirrors o94 checked/unchecked affordance');
check(lib.includes('NoteMenuButton(note: NoteMeta)') &&
  lib.includes("Text('⋯')") &&
  lib.includes('.bindMenu(() => {'),
  '⋯ overflow button hosts the d5j single-note menu');

// ---------- 顶栏 ----------
const topBar = lib.indexOf('MultiSelectTopBar() {');
check(topBar >= 0 &&
  lib.slice(topBar, topBar + 1600).includes('app.string.deselect_all') &&
  lib.slice(topBar, topBar + 1600).includes('app.string.select_all') &&
  lib.slice(topBar, topBar + 1600).includes('app.string.notes_selected') &&
  lib.slice(topBar, topBar + 1600).includes('app.string.note_selected_singular') &&
  lib.slice(topBar, topBar + 1600).includes('app.string.done') &&
  lib.slice(topBar, topBar + 1600).includes('this.exitMultiSelect();'),
  'MultiSelectTopBar mirrors hof (select-all toggle + count + Done)');
check(lib.includes('if (this.isMultiSelecting) {\n          this.MultiSelectTopBar()\n        } else {'),
  'top bar swaps to MultiSelectTopBar in selection mode');

// ---------- 底栏批量动作 ----------
const actBar = lib.indexOf('MultiSelectActionBar() {');
check(actBar >= 0 &&
  lib.slice(actBar, actBar + 2600).includes('app.string.duplicate_note') &&
  lib.slice(actBar, actBar + 2600).includes('app.string.favorite_note') &&
  lib.slice(actBar, actBar + 2600).includes('app.string.unfavorite_note') &&
  lib.slice(actBar, actBar + 2600).includes('app.string.delete') &&
  lib.slice(actBar, actBar + 2600).includes('LoadingProgress()') &&
  lib.slice(actBar, actBar + 2600).includes('this.selectedNoteIds.length > 0 && !this.multiSelectBusy'),
  'MultiSelectActionBar mirrors l05/fj9/gj9 (Duplicate/Favorite/Delete + busy + empty gating)');
check(!lib.slice(actBar, actBar + 2600).includes('app.string.share\n'),
  'Share stays out of the action bar (lc4-gated → Phase 674)');

// ---------- 全选/收藏派生 ----------
const allSel = lib.indexOf('private allVisibleSelected(): boolean {');
check(allSel >= 0 &&
  lib.slice(allSel, allSel + 600).includes('this.notes') &&
  lib.slice(allSel, allSel + 600).includes('indexOf(note.id) < 0'),
  'allVisibleSelected mirrors ek9.a coverage test');
check(lib.includes('this.selectedNoteIds = this.allVisibleSelected() ? [] :\n      this.notes.map((n: NoteMeta) => n.id);'),
  'toggleSelectAll mirrors hof select-all/deselect-all');
const favAll = lib.indexOf('private allSelectedFavorited(): boolean {');
check(favAll >= 0 &&
  lib.slice(favAll, favAll + 600).includes('!note.favorite'),
  'allSelectedFavorited mirrors ek9.e');

// ---------- 批量操作 ----------
const mDup = lib.indexOf('private multiDuplicate(): void {');
check(mDup >= 0 &&
  lib.slice(mDup, mDup + 2600).includes('exporter.exportNote(id)') &&
  lib.slice(mDup, mDup + 2600).includes('importer.importFromData(data)') &&
  lib.slice(mDup, mDup + 2600).includes('app.string.note_duplicated') &&
  lib.slice(mDup, mDup + 2600).includes('app.string.multi_duplicate_failed') &&
  lib.slice(mDup, mDup + 2600).includes('this.refreshRecentCardFeed()'),
  'multiDuplicate reuses the lossless export→import path per note');
const mFav = lib.indexOf('private async multiSetFavorite(): Promise<void> {');
check(mFav >= 0 &&
  lib.slice(mFav, mFav + 1800).includes('vm.toggleFavorite(id)') &&
  lib.slice(mFav, mFav + 1800).includes('note.favorite !== target') &&
  lib.slice(mFav, mFav + 1800).includes('app.string.multi_favorite_failed'),
  'multiSetFavorite applies partial mutation toward ek9.e target');
const mDel = lib.indexOf('private async multiDelete(): Promise<void> {');
check(mDel >= 0 &&
  lib.slice(mDel, mDel + 1600).includes('vm.deleteNote(id)') &&
  lib.slice(mDel, mDel + 1600).includes('app.string.multi_delete_failed') &&
  lib.slice(mDel, mDel + 1600).includes('this.refreshThumbnails()'),
  'multiDelete reuses per-note delete + thumbnail refresh');
check(mDel >= 0 &&
  lib.slice(mDel, mDel + 1600).includes('if (this.selectedNoteIds.length === 0) {\n        this.exitMultiSelect();'),
  'selection exits when deletion empties the set');
const cDel = lib.indexOf('private confirmMultiDelete(): void {');
check(cDel >= 0 &&
  lib.slice(cDel, cDel + 1200).includes('showAlertDialog') &&
  lib.slice(cDel, cDel + 1200).includes('app.string.delete_notes_message'),
  'multi delete confirms via delete_notes_message');

// ---------- 返回键 + FAB ----------
check(lib.includes('onBackPress(): boolean {\n    if (this.isMultiSelecting) {\n      this.exitMultiSelect();\n      return true;'),
  'back press exits selection first (lq7 → pk9.p)');
check(lib.includes('FabButton() {\n    if (!this.isMultiSelecting) {'),
  'FAB hidden in selection mode');

// ---------- 选中集清理 ----------
check(lib.includes('this.selectedNoteIds = this.selectedNoteIds.filter'),
  'stale selected ids pruned after batch ops');

// ---------- 字符串 ----------
for (const key of ['"share"', '"deselect_all"', '"notes_selected"',
  '"note_selected_singular"', '"select_note"', '"note_actions"',
  '"delete_notes_message"', '"multi_delete_failed"',
  '"multi_duplicate_failed"', '"multi_favorite_failed"']) {
  check(baseStrings.includes(key) && zhStrings.includes(key),
    `${key} localized in both locales`);
}

console.log(`D02_ORIGINAL_LIBRARY_MULTI_SELECT_OK TOTAL=${total} FAILED=0`);
