// D02 原版 1.4.2 贴纸管理器 + 纸模板分类法 — Phase 783
// 钉住四页签、自建贴纸提示串、约 40 个具名包键、五类目法。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const s142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('sticker manager four tabs: all/favorites/my_stickers/recents',
  ['all', 'favorites', 'my_stickers', 'recents']
    .every((k) => s142.includes(`feature_note_stickers__${k}">`)));
check('create-sticker-from-own-ink hint exists (local-feasible path)',
  s142.includes('Select your ink, then tap %1$s in the selection menu'));
check('favorites affordance + delete cross-device sync copy',
  s142.includes('Press and hold a sticker, then tap the star')
  && s142.includes('removed from all your devices'));
check('~40 named sticker packs registered as keys',
  (s142.match(/feature_note_stickers__pack_[a-z_0-9]*">/g) || []).length >= 38);
check('pack download surface present (store boundary)',
  s142.includes('feature_note_stickers__download_pack">')
  && s142.includes('pack_download_failed'));
check('1.0.3 had no sticker-manager keys at all',
  !s103.includes('feature_note_stickers__'));
check('paper-template category taxonomy = five groups',
  ['academic', 'creative', 'notepads', 'planning', 'self_care']
    .every((k) => s142.includes(`ui_papertemplates__${k}">`))
  && !s103.includes('ui_papertemplates__'));

console.log(`sticker-manager replay: ${checks.length}/${checks.length} checks green`);
