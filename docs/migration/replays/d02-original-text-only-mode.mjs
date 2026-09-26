// D02 原版 1.4.2 文本专属模式 — Phase 773（版本差·本地候选）
// 钉住 isTextOnly 持久化路径、选项菜单项与三态横幅文案。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const strings = `${base}/resources/res/values/strings.xml`;
const ws3 = `${base}/sources/defpackage/ws3.java`;
const xf3 = `${base}/sources/defpackage/xf3.java`;
const zmb = `${base}/sources/defpackage/zmb.java`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const s = fs.readFileSync(strings, 'utf8');
check('options-menu toggle entry exists',
  s.includes('feature_note__options_menu_text_only">Text only'));
check('on/off banner pair + dismiss + notice + auto-exit strings complete',
  s.includes('text_only_banner_on_title') && s.includes('text_only_banner_off_title')
  && s.includes('text_only_banner_dismiss') && s.includes('text_only_notice_message')
  && s.includes('text_only_auto_exit'));
check('auto-exit toast reads "Showing the full note"',
  s.includes('text_only_auto_exit">Showing the full note'));

check('isTextOnly read via per-note SELECT on NoteStateEntity',
  fs.readFileSync(ws3, 'utf8').includes('SELECT isTextOnly FROM NoteStateEntity where id = ?'));
check('isTextOnly written via per-note UPDATE',
  fs.readFileSync(xf3, 'utf8').includes('UPDATE NoteStateEntity SET isTextOnly = ? WHERE id = ?'));
check('column added via ALTER migration (nullable INTEGER)',
  fs.readFileSync(zmb, 'utf8').includes('ALTER TABLE `NoteStateEntity` ADD COLUMN `isTextOnly` INTEGER DEFAULT NULL'));

console.log(`text-only mode replay: ${checks.length}/${checks.length} checks green`);
