// D02 原版文件夹删除级联 + kcj 计数矩阵 — Phase 717（ADR-0665，取代 ADR-0158）。
// kcj.a(title, i=子文件夹数, i2=子树笔记数)：9 格分支（0,0 → 无 detail），
// "will also delete" 契约 = 笔记随删除进回收站（fq4.k()=后代文件夹数、
// h()=子树笔记 id 集，vad.java:143 构造）。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const kcj = read(`${JADX}/sources/defpackage/kcj.java`);
const gsi = read(`${JADX}/sources/defpackage/gsi.java`);
const vad = read(`${JADX}/sources/defpackage/vad.java`);
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const repo = read('note/src/main/ets/data/FolderRepositoryImpl.ets');
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const vm = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版证据 ---
check(strings.includes('ui_folder__delete_folder_single_folder'),
  '原版 delete_folder_single_folder');
check(strings.includes('ui_folder__delete_folder_plural_folders_plural_notes'),
  '原版 delete_folder_plural_folders_plural_notes');
check(/will also delete 1 folder and %2\$d notes/.test(strings),
  '原版混合复数文案 "will also delete"');
for (const k of ['single_folder', 'plural_folders', 'single_note', 'plural_notes',
  'single_folder_single_note', 'single_folder_plural_notes',
  'plural_folder_single_note', 'plural_folders_plural_notes']) {
  check(kcj.includes(`ui_folder__delete_folder_${k}`), `kcj 分支引用 ${k}`);
}
check(/i == 0 && i2 == 0[\s\S]{0,120}strT = null/.test(kcj),
  'kcj 0,0 → 无 detail 文本');
check(/kcj\.a\(title, iK, size/.test(gsi), 'gsi 调用 kcj.a(title, iK, size)');
check(vad.includes('arrayList3.size(), iK, au1.X1(arrayListA1)'),
  'vad 构造 dq4：i=递归后代文件夹数，h()=子树笔记 id 集');
check(strings.includes('ui_folder__dialog_confirm') &&
  strings.includes('ui_folder__dialog_cancel'), '原版 confirm/cancel 资源');

// --- Harmony 移植：级联回收站语义 ---
check(repo.includes("'folder_id': null, 'deleted_at': trashedAt"),
  'deleteFolder 子树笔记 folder_id=NULL + deleted_at 盖章');
check(repo.includes('const trashedAt: number = Date.now()'), 'trashedAt 时间戳');
check(vm.includes('note.deletedAt === null'),
  'ViewModel 根列表过滤已回收笔记');
check(/if \(moved\.has\(note\.id\)\) \{\s*\/\/ 原版 kcj[^}]*continue;/s.test(vm),
  'ViewModel 剔除随删笔记卡片');

// --- Harmony 移植：kcj 九格矩阵 ---
check(page.includes('folderDeleteDetail(folder.name'), 'confirmDeleteFolder 走矩阵 helper');
check(page.includes('const childFolders: number = subtreeIds.length - 1'),
  'childFolders = 子树含根 - 1 = 后代数');
check(page.includes('isFolderInSubtree(this.folders, folder.id, f.id)'),
  '子树遍历用 isFolderInSubtree');
check(page.includes("$r('app.string.delete_folder_message')") &&
  /"delete_folder_message",\s*"value": "Delete folder\?"/.test(en.replace(/\n/g, ' ')) ||
  en.includes('"value": "Delete folder?"'),
  '对话框标题 = "Delete folder?"');
for (const k of ['empty', '1f', 'nf', '1n', 'nn', '1f_1n', '1f_nn', 'nf_1n', 'nf_nn']) {
  check(en.includes(`"folder_delete_detail_${k}"`), `en detail key ${k}`);
  check(zh.includes(`"folder_delete_detail_${k}"`), `zh detail key ${k}`);
}
check(en.includes('Deleting \\"%s\\" will also delete 1 folder and %d notes.') ||
  en.includes('Deleting "%s" will also delete 1 folder and %d notes.'),
  'en 1f_nn 文案对齐原版');
check(zh.includes('将同时删除 %d 个文件夹和 %d 条笔记'), 'zh nf_nn 文案');

console.log(`TOTAL=${total} FAILED=0`);
