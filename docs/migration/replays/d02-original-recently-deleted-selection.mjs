// Phase 1418 — 原版 Recently Deleted 选择制 parity
// 证据链：p6e/invokeSuspend 组装 a6e 模型（a=select_all/deselect_all
// 切换文案，b=notes_selected 复数横幅，c=z5e 行表，d=选集非空使能位，
// e=delete_confirmation_message 复数正文，g=列表空）；
// wrl.i = [Select all/Deselect all 文本行 -> j6e] + [N selected 横幅]；
// th3 -> wrl.h = fq9.p 整行点击 -> oe(24) -> g6e(bpj) 选择切换，
// x8n.a 行尾 mo2(7)=f9n.b 复选框（cd_select/cd_deselect_note_titled）；
// v5e case0 底部条 = Delete(delete_notes, mma.G 危险色) +
// Recover notes(recover_notes)，均以 a6e.d 门控；
// wrl.b -> l8n.c 删除确认 = 复数正文 + [Keep notes]/[Delete]，
// 无标题位（iqm 调用点可证 str 槽位为确认钮文案）。
// 原版无逐行 Recover/Delete 按钮、无搜索框。
// fail-closed：wrl.f -> l8n.e note_limit_recover_* 上限挽留（付费墙）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage';
const R = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values';
const H = 'C:/HarmonyProject/NotaHarmony/note/src/main';

const checks = [];
const check = (name, cond) => {
  assert.equal(cond, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = (p) => fs.readFileSync(p, 'utf8');

// ── 原版钉：模型 ──
const p6e = read(`${S}/p6e.java`);
check('p6e：全选态判定 zx7.r(set, map.keySet()) 切 select_all/deselect_all',
  p6e.includes('zx7.r(set, map.keySet())') &&
  p6e.includes('R.string.feature_settings__deselect_all') &&
  p6e.includes('R.string.feature_settings__select_all'));
check('p6e：a6e.b = notes_selected 复数（set.isEmpty() ? null : d8d）',
  p6e.includes('R.plurals.feature_settings__notes_selected') &&
  p6e.includes('set.isEmpty()'));
check('p6e：a6e.e = delete_confirmation_message 复数（z=删除确认态时构建）',
  p6e.includes('R.plurals.feature_settings__delete_confirmation_message') &&
  p6e.includes('set.size()'));
check('p6e：a6e.d = !set.isEmpty()（批量动作使能位）',
  p6e.includes('boolean z3 = !set.isEmpty()'));
check('p6e：z5e 行模型带 set.contains(w9bVar) 选中位',
  p6e.includes('set.contains(w9bVar)') && p6e.includes('new z5e('));
check('p6e：行副文 = feature_settings__note_deleted_at + zq.M 中日期',
  p6e.includes('R.string.feature_settings__note_deleted_at'));

// ── 原版钉：渲染器 ──
const wrl = read(`${S}/wrl.java`);
check('wrl.i：Select-all 文本行 o9n.a(a6e.a) + onClick w5e(5)',
  wrl.includes('a6eVar.a.a(nc6Var)') && wrl.includes('new w5e(bz5Var, (byte) 5)'));
check('wrl.i：N-selected 横幅 x7n.e(p0h!=null)（即 a6e.b）',
  wrl.includes('x7n.e(strA != null'));
check('wrl.b：删除确认 = l8n.c(delete_notes + keep_notes + gbb(7) 正文)',
  wrl.includes('l8n.c(function0, strW0') &&
  wrl.includes('R.string.feature_settings__delete_notes') &&
  wrl.includes('R.string.feature_settings__keep_notes'));
check('wrl.h：整行 fq9.p 可点击（function0 = 选择切换回调）',
  wrl.includes('fq9.p(w8aVar, false, null, null, function0, 15)'));

const v5e = read(`${S}/v5e.java`);
check('v5e case0：Delete(delete_notes, mma.G) + Recover notes(recover_notes)',
  v5e.includes('R.string.feature_settings__delete_notes') &&
  v5e.includes('R.string.feature_settings__recover_notes') &&
  v5e.includes('mma.G'));
check('v5e case0：两个批量按钮均以 a6eVar.d 门控',
  (v5e.match(/a6eVar\.d/g) || []).length >= 2);

const mo2 = read(`${S}/mo2.java`);
check('mo2 case7：f9n.b 复选框 cd = select/deselect_note_titled',
  mo2.includes('R.string.feature_settings__cd_deselect_note_titled') &&
  mo2.includes('R.string.feature_settings__cd_select_note_titled'));

const w5e = read(`${S}/w5e.java`);
check('w5e：case5 -> j6e（全选切换）+ case2/3 -> 批量删除/恢复动作',
  w5e.includes('bz5Var.invoke(j6e.a)') &&
  w5e.includes('bz5Var.invoke(h6e.a)'));

const th3 = read(`${S}/th3.java`);
check('th3：行渲染 wrl.h(...z5e.f 选中位, oe(24) 点击回调)',
  th3.includes('wrl.h(w8aVarA, bpjVar') && th3.includes('z5eVar.f') &&
  th3.includes('new oe('));

// ── 原版资源钉 ──
const strings = read(`${R}/strings.xml`);
for (const [key, value] of [
  ['feature_settings__select_all', 'Select all'],
  ['feature_settings__deselect_all', 'Deselect all'],
  ['feature_settings__recover_notes', 'Recover notes'],
  ['feature_settings__delete_notes', 'Delete'],
  ['feature_settings__keep_notes', 'Keep notes'],
]) {
  check(`原版 strings.xml ${key}`, strings.includes(`name="${key}">${value}<`));
}
const plurals = read(`${R}/plurals.xml`);
check('原版 plurals notes_selected（one/other）',
  plurals.includes('name="feature_settings__notes_selected"') &&
  plurals.includes('%1$d note selected') && plurals.includes('%1$d notes selected'));
check('原版 plurals delete_confirmation_message（one/other）',
  plurals.includes('name="feature_settings__delete_confirmation_message"') &&
  plurals.includes('Permanently delete %1$d note?'));

// ── Harmony 实现钉 ──
const page = read(`${H}/ets/ui/settings/RecentlyDeletedPage.ets`);
check('选择态：@State selectedTrashIds: string[]',
  page.includes('@State selectedTrashIds: string[]'));
check('toggleSelectAll：全选<->清空（selected==trashedNotes.length 判定）',
  page.includes('selectedTrashIds.length === this.trashedNotes.length') &&
  page.includes('trashedNotes.map((n: NoteMeta) => n.id)'));
check('toggleNoteSelection：includes -> filter/spread 切换',
  page.includes('selectedTrashIds.includes(noteId)') &&
  page.includes('selectedTrashIds.filter((id: string) => id !== noteId)'));
check('行复选框：Checkbox().select + cd_select/deselect_note_titled + hitTestBehavior(None)',
  page.includes('Checkbox()') && page.includes('cd_deselect_note_titled') &&
  page.includes('cd_select_note_titled') &&
  page.includes('hitTestBehavior(HitTestMode.None)'));
check('整行点击 -> toggleNoteSelection（fq9.p/g6e 等价）',
  /onClick\(\(\) => \{\s*this\.toggleNoteSelection\(note\.id\)/.test(page));
check('顶部 Select all/Deselect all 行（o9n.a/j6e 等价）',
  page.includes("app.string.feature_settings__deselect_all") &&
  page.includes('toggleSelectAll();'));
check('N-selected 横幅（notes_selected one/other + 选集非空条件）',
  page.includes('selectedTrashIds.length > 0') &&
  page.includes('feature_settings__notes_selected_one') &&
  page.includes('feature_settings__notes_selected_other'));
check('底部批量条：delete_notes + recover_notes，均 enabled=选集非空',
  page.includes("app.string.feature_settings__delete_notes") &&
  page.includes("app.string.feature_settings__recover_notes") &&
  (page.match(/enabled\(this\.selectedTrashIds\.length > 0 && !this\.busy\)/g) || []).length >= 2);
check('删除确认：delete_confirmation_message one/other + keep_notes/delete_notes 按钮',
  page.includes('confirmDeleteSelected') &&
  page.includes('feature_settings__delete_confirmation_message_one') &&
  page.includes('feature_settings__delete_confirmation_message_other') &&
  page.includes('feature_settings__keep_notes'));
check('批量动作：recoverSelected -> restoreNote(id)；permanentlyDeleteSelected -> deleteNote(id)',
  page.includes('repo.restoreNote(id)') && page.includes('repo.deleteNote(id)'));
check('无逐行 recover_note/delete 按钮残留（原版批量制）',
  !/\$r\('app\.string\.recover_note'\)/.test(page) &&
  !page.includes('confirmPermanentlyDelete'));
check('fail-closed 标记：note_limit_recover_* 付费墙说明在注释中',
  page.includes('note_limit_recover'));
check('列表重载时剪除失效选中 id（选集与列表同状态流语义）',
  page.includes('stillPresent') && page.includes('selectedTrashIds = this.selectedTrashIds.filter'));

const en = read(`${H}/resources/base/element/string.json`);
const zh = read(`${H}/resources/zh_CN/element/string.json`);
for (const key of [
  'feature_settings__deselect_all',
  'feature_settings__notes_selected_one', 'feature_settings__notes_selected_other',
  'feature_settings__delete_confirmation_message_one',
  'feature_settings__delete_confirmation_message_other',
  'feature_settings__recover_notes', 'feature_settings__delete_notes',
  'feature_settings__keep_notes',
]) {
  check(`en 缺 ${key}`, en.includes(`"name": "${key}"`));
  check(`zh 缺 ${key}`, zh.includes(`"name": "${key}"`));
}
check('en 值：Deselect all / Recover notes / Keep notes',
  en.includes('"Deselect all"') && en.includes('"Recover notes"') &&
  en.includes('"Keep notes"'));

console.log(`\n${checks.length} checks passed`);
