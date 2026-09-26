// D02 原版 1.4.2 大纲解析管道与新增异常族 — Phase 772
// 钉住 syllabus 服务端解析 UX 链、SyllabusParseException 归属与新增异常清单。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const strings = `${base}/resources/res/values/strings.xml`;
const syl = `${base}/sources/com/gingerlabs/notability/data/learn/syllabus`;
const notelimit = `${base}/sources/com/gingerlabs/notability/data/library/state/notelimit`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const s = fs.readFileSync(strings, 'utf8');
check('syllabus import offers file + photo entry points',
  s.includes('ui_learn__syllabus_choose_file') && s.includes('ui_learn__syllabus_choose_photos'));
check('server-side parse states incl. busy/timeout/too-large errors',
  s.includes('syllabus_parsing_body')
  && s.includes('syllabus_error_server_busy')
  && s.includes('syllabus_error_timed_out')
  && s.includes('syllabus_error_too_large')
  && s.includes('syllabus_error_not_syllabus'));
check('review banner + sections + fallback course name complete the flow',
  s.includes('syllabus_review_banner') && s.includes('syllabus_exams_section')
  && s.includes('syllabus_recurring_section') && s.includes('syllabus_fallback_course_name'));

check('SyllabusParseException lives in the Learn cluster',
  fs.existsSync(`${syl}/SyllabusParseException.java`));
check('NoteLimitRefusedException lives under library/state/notelimit',
  fs.existsSync(`${notelimit}/NoteLimitRefusedException.java`));

console.log(`syllabus parse replay: ${checks.length}/${checks.length} checks green`);
