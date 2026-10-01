// Phase 1416 — 原版窄屏库 chrome 无障碍 parity
// 证据链：mf2 case21 → i87.b(hamburger, ui_librarypane__cd_organize)；
// ihm.a 用 wv9.b(t0c.R,2) 包该钮（COMPACT_ORGANIZE 锚点）；
// fla ModalDrawer 遮罩 tuf.b(semantics=close_drawer)+nfh.b 点击关闭；
// ybn 文件夹对话框 cd_folder_name(输入框)/cd_confirm(确认钮)。
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const REPO = 'C:/HarmonyProject/NotaHarmony';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage';
const STR = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml';

const checks = [];
const check = (name, cond) => {
  assert.equal(cond, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = (p) => fs.readFileSync(p, 'utf8');

// ── 原版钉 ──
const mf2 = read(`${S}/mf2.java`);
check('mf2 case21：hamburger 图标钮 cd = ui_librarypane__cd_organize',
  mf2.includes('R.drawable.ui_designsystem__hamburger') &&
  mf2.includes('R.string.ui_librarypane__cd_organize'));

const ihm = read(`${S}/ihm.java`);
check('ihm.a：ihm 钮经 wv9.b(t0c.R=COMPACT_ORGANIZE, 槽位2) 锚定',
  ihm.includes('t0c.R') && ihm.includes('wv9.b(t0cVar, 2'));

const fla = read(`${S}/fla.java`);
check('fla 遮罩：close_drawer 语义 + nfh.b 点击关闭',
  fla.includes('R.string.close_drawer') && fla.includes('nfh.b'));

const ybn = read(`${S}/ybn.java`);
check('ybn：cd_confirm(确认钮) 与 cd_folder_name(名称框) 语义',
  ybn.includes('R.string.ui_folder__cd_confirm') &&
  ybn.includes('R.string.ui_folder__cd_folder_name'));

const str = read(STR);
check('原版字串：cd_organize/close_drawer/cd_folder_name/cd_confirm',
  str.includes('"ui_librarypane__cd_organize">Organize') &&
  str.includes('"close_drawer">Close navigation menu') &&
  str.includes('"ui_folder__cd_folder_name">Folder name') &&
  str.includes('"ui_folder__cd_confirm">Save folder'));

// ── Harmony 钉 ──
const lp = read(path.join(REPO, 'note/src/main/ets/ui/library/LibraryPage.ets'));
check('hamburger 钮 cd → ui_librarypane__cd_organize',
  /glyph: 'hamburger'[\s\S]*?accessibilityText\(\$r\('app\.string\.ui_librarypane__cd_organize'\)\)/.test(lp));
check('遮罩 cd → close_drawer 且维持点击关闭',
  /accessibilityText\(\$r\('app\.string\.close_drawer'\)\)[\s\S]{0,120}closeCompactFolderDrawer/.test(lp));
check('文件夹名钮无覆盖 cd（以名自标识）',
  !/Button\(this\.currentFolderName\(\)\)[\s\S]{0,300}accessibilityText/.test(lp));
check('文件夹对话框：名称框 cd_folder_name + 确认钮 cd_confirm',
  lp.includes("accessibilityText($r('app.string.ui_folder__cd_folder_name'))") &&
  lp.includes("accessibilityText($r('app.string.ui_folder__cd_confirm'))"));
check('虚构串 open_folder_drawer 已移除',
  !lp.includes('open_folder_drawer'));

const base = read(path.join(REPO, 'note/src/main/resources/base/element/string.json'));
const zh = read(path.join(REPO, 'note/src/main/resources/zh_CN/element/string.json'));
for (const k of ['ui_librarypane__cd_organize', 'close_drawer',
  'ui_folder__cd_folder_name', 'ui_folder__cd_confirm']) {
  check(`en/zh 在档：${k}`,
    base.includes(`"${k}"`) && zh.includes(`"${k}"`));
}
check('en 值逐字：Organize / Close navigation menu / Folder name / Save folder',
  base.includes('"ui_librarypane__cd_organize", "value": "Organize"') &&
  base.includes('"close_drawer", "value": "Close navigation menu"') &&
  base.includes('"ui_folder__cd_folder_name", "value": "Folder name"') &&
  base.includes('"ui_folder__cd_confirm", "value": "Save folder"'));
check('串表无 open_folder_drawer 残留',
  !base.includes('open_folder_drawer') && !zh.includes('open_folder_drawer'));

console.log(`\nlibrary-drawer-a11y replay: ${checks.length}/${checks.length} checks green`);
