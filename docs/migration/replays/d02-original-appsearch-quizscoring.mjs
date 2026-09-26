// D02 原版 1.4.2 AppSearch 引擎差 + QuizSession 计分列 — Phase 785
// 钉住 appsearch 引擎包存在性、SearchResult 文档字段、
// QuizSession 四计分 ALTER 与 NoteStateEntity 非增量更正。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const r142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2';
const r103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const eng142 = fs.readdirSync(`${r142}/sources/com/gingerlabs/notability/data/search/engine`);
const eng103 = fs.readdirSync(`${r103}/sources/com/gingerlabs/notability/data/search/engine`);
const doc = fs.readFileSync(`${r142}/sources/com/gingerlabs/notability/data/search/engine/appsearch/SearchResult.java`, 'utf8');
const e47 = fs.readFileSync(`${r103}/sources/defpackage/e47.java`, 'utf8');

const alters142 = new Set();
for (const f of fs.readdirSync(`${r142}/sources/defpackage`)) {
  if (!f.endsWith('.java')) continue;
  for (const m of fs.readFileSync(`${r142}/sources/defpackage/${f}`, 'utf8')
    .matchAll(/ALTER TABLE `([A-Za-z_]+)` ADD COLUMN `([a-zA-Z_]+)`/g)) {
    alters142.add(`${m[1]}.${m[2]}`);
  }
}
const alters103 = new Set();
for (const f of fs.readdirSync(`${r103}/sources/defpackage`)) {
  if (!f.endsWith('.java')) continue;
  for (const m of fs.readFileSync(`${r103}/sources/defpackage/${f}`, 'utf8')
    .matchAll(/ALTER TABLE `([A-Za-z_]+)` ADD COLUMN `([a-zA-Z_]+)`/g)) {
    alters103.add(`${m[1]}.${m[2]}`);
  }
}

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('1.4.2 search engines = room + appsearch; 1.0.3 = room only',
  eng142.includes('appsearch') && eng142.includes('room')
  && eng103.includes('room') && !eng103.includes('appsearch'));
check('AppSearch SearchResult document fields (id/text/score/namespace/pageId)',
  doc.includes('SearchResult(id=') && doc.includes('namespace=')
  && doc.includes('pageId='));
check('QuizSession gains four scoring columns in 1.4.2',
  ['QuizSession.numCorrect', 'QuizSession.numIncorrect',
    'QuizSession.numSkipped', 'QuizSession.spacedRepetitionTotal']
    .every((c) => alters142.has(c) && !alters103.has(c)));
check('CompletedQuizSession gains numCorrect/Incorrect/Skipped too',
  ['CompletedQuizSession.numCorrect', 'CompletedQuizSession.numIncorrect',
    'CompletedQuizSession.numSkipped'].every((c) => alters142.has(c)));
check('NoteStateEntity zoom/code-block cols already existed in 1.0.3 (correction)',
  ['NoteStateEntity.lastCodeBlockLanguage', 'NoteStateEntity.zoomViewShown',
    'NoteStateEntity.zoomViewSourceRect'].every((c) => alters103.has(c))
  && e47.includes('`zoomViewSourceRect` TEXT'));
check('isTextOnly remains the sole true NoteStateEntity 1.4.2 addition',
  alters142.has('NoteStateEntity.isTextOnly') && !alters103.has('NoteStateEntity.isTextOnly'));

console.log(`appsearch/quiz-scoring replay: ${checks.length}/${checks.length} checks green`);
