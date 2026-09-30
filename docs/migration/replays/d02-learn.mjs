// Phase 1289 — data/learn AI study feature
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/learn/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const db = R('database/LearnDatabase.java');
t('LearnDatabase extends x5c RoomDB', db.includes('extends x5c'));
const impl = R('database/LearnDatabase_Impl.java');
t('LearnJob entity', impl.includes('LearnJob'));
t('LearnNoteState entity', impl.includes('LearnNoteState'));
t('QuizOp entity', impl.includes('QuizOp'));
t('QuizSession entity', impl.includes('QuizSession'));
t('StudyItemsInfo entity', impl.includes('StudyItemsInfo'));
t('SummaryEntity', impl.includes('SummaryEntity'));
t('LearnError', X('LearnError.java'));
const le = R('LearnError.java');
t('LearnError exception', le.includes('Exception') || le.includes('Error'));
const a = R('a.java');
t('DAO impls a/b', a.length > 0 && X('b.java'));
console.log('learn replay: ' + n + '/10 checks green');
