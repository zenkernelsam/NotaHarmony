// D02 原版文件夹对话框标签 + 选中行 a11y — Phase 718（ADR-0666）。
// gaj.java:630/719：z8（创建）? new_folder : enter_folder_name —— 重命名
// 对话框标题与字段标签同为 "Enter folder name"；b41.java:94/o94.java:171：
// 选中指示节点 contentDescription = ui_folder__selected ("Selected")。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const gaj = read(`${JADX}/sources/defpackage/gaj.java`);
const b41 = read(`${JADX}/sources/defpackage/b41.java`);
const o94 = read(`${JADX}/sources/defpackage/o94.java`);
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版证据 ---
check(strings.includes('ui_folder__enter_folder_name') &&
  strings.includes('>Enter folder name<'), '原版 enter_folder_name 文案');
check(strings.includes('ui_folder__new_folder') &&
  strings.includes('ui_folder__selected'), '原版 new_folder/selected 键');
check(/z8[\s\S]{0,80}ui_folder__new_folder[\s\S]{0,120}ui_folder__enter_folder_name/
  .test(gaj) || (gaj.match(/enter_folder_name/g) || []).length >= 2,
  'gaj 创建/重命名标题择一（new_folder | enter_folder_name）');
check(b41.includes('ui_folder__selected') && o94.includes('ui_folder__selected'),
  'b41/o94 选中指示节点引用 selected 语义');

// --- Harmony 移植 ---
check(page.includes("this.folderDialogTitle = $r('app.string.enter_folder_name')"),
  '文件夹重命名标题 = enter_folder_name');
check(page.includes("placeholder: $r('app.string.enter_folder_name')"),
  '文件夹对话框字段标签 = enter_folder_name');
check(/placeholder: ResourceStr = \$r\('app\.string\.name'\)/.test(page),
  'NameDialog placeholder 默认 name（笔记重命名保持）');
check(page.includes('TextInput({ text: this.inputText, placeholder: this.placeholder })'),
  'TextInput 走 placeholder prop');
check(/Text\('✓'\)[\s\S]{0,200}accessibilityText\(\$r\('app\.string\.folder_selected'\)\)/
  .test(page), '选中 ✓ 指示带 folder_selected 语义');
check(/\.accessibilityText\(item\.folder\.name\)/.test(page),
  '文件夹行语义仍朗读文件夹名');
check(en.includes('"enter_folder_name", "value": "Enter folder name"') &&
  en.includes('"folder_selected", "value": "Selected"'), 'en 双键');
check(zh.includes('"enter_folder_name", "value": "输入文件夹名称"') &&
  zh.includes('"folder_selected", "value": "已选中"'), 'zh 双键');

console.log(`TOTAL=${total} FAILED=0`);
