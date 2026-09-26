// D02 原版 1.4.2 闪卡导入管线 — Phase 779
// 钉住 zf5 格式枚举、APKG 本地 ZIP+anki 集合白名单、64MB 条目守卫、
// 双级分隔符键族与配额边界键。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const r142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const s142 = fs.readFileSync(`${r142}/resources/res/values/strings.xml`, 'utf8');
const s103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const zf5 = fs.readFileSync(`${r142}/sources/defpackage/zf5.java`, 'utf8');
const qpl = fs.readFileSync(`${r142}/sources/defpackage/qpl.java`, 'utf8');
const uf5 = fs.readFileSync(`${r142}/sources/defpackage/uf5.java`, 'utf8');
const mub = fs.readFileSync(`${r142}/sources/defpackage/mub.java`, 'utf8');
const trl = fs.readFileSync(`${r142}/sources/defpackage/trl.java`, 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('zf5 enum = APKG/CSV/TSV/TXT/Other',
  ['APKG("APKG")', 'CSV("CSV")', 'TSV("TSV")', 'TXT("TXT")', 'Other("Other")']
    .every((e) => zf5.includes(e)));
check('qpl maps request ordinals 0-4 onto zf5 variants',
  qpl.includes('zf5.APKG') && qpl.includes('zf5.CSV')
  && qpl.includes('zf5.TSV') && qpl.includes('zf5.TXT'));
check('APKG targets Anki collection files (anki21b/anki21/anki2)',
  uf5.includes('collection.anki21b') && uf5.includes('collection.anki21')
  && uf5.includes('collection.anki2'));
check('APKG unpack is local ZipFile with 64MB entry guard',
  trl.includes('java.util.zip.ZipFile') && trl.includes('getInputStream')
  && mub.includes('67108864') && mub.includes('entry too large'));
check('delimiter model: comma/semicolon/tab/new_line/custom + two levels',
  ['delimiter_comma', 'delimiter_semicolon', 'delimiter_tab', 'delimiter_new_line',
    'delimiter_custom', 'between_term_and_definition', 'between_rows']
    .every((k) => s142.includes(`flashcard_import_${k}">`)));
check('manual-paste + file + error + quota keys all present',
  ['manual_instructions', 'paste_example', 'file_title', 'file_instructions',
    'failed_title', 'unsupported_file_type', 'quota_title']
    .every((k) => s142.includes(`flashcard_import_${k}">`)));
check('1.0.3 had zero flashcard_import_* keys (family is 1.4.2-new)',
  !s103.includes('flashcard_import_'));

console.log(`flashcard-import replay: ${checks.length}/${checks.length} checks green`);
