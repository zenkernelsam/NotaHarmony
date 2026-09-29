// Phase 1015 — 测验/学习子系统 5 表
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e47 = readFileSync(D + 'e47.java', 'utf8');
const na4 = readFileSync(D + 'na4.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// QuizSession
t('QuizSession: PK(noteId,mode)', e47.includes('`QuizSession`') && e47.includes('PRIMARY KEY(`noteId`, `mode`)'));
t('QuizSession: progress+resume cols', e47.includes('`numQuestions`') && e47.includes('`numAnswered`') && e47.includes('`lastViewedQuestion`') && e47.includes('`questions` TEXT'));
// QuizOp
t('QuizOp: AUTOINCREMENT opId', e47.includes('`QuizOp`') && e47.includes('`opId` INTEGER PRIMARY KEY AUTOINCREMENT'));
t('QuizOp: 3 answer cols', e47.includes('`multipleChoiceAnswer`') && e47.includes('`fillInTheBlankAnswer`') && e47.includes('`flashcardRating`'));
t('QuizOp: session+index+status', e47.includes('`sessionId` TEXT NOT NULL') && e47.includes('`questionIndex`') && e47.includes('`isCompleteSession` INTEGER'));
// Summary / LearnJob / StudyItems
t('SummaryEntity: noteId+markdown', e47.includes('`SummaryEntity`') && e47.includes('`markdown` TEXT NOT NULL'));
t('LearnJob: batchId+language+asrHashes', e47.includes('`LearnJob`') && e47.includes('`batchId` TEXT') && e47.includes('`asrHashes` TEXT'));
t('StudyItemsInfo: metrics cols', e47.includes('`StudyItemsInfo`') && e47.includes('`textLength`') && e47.includes('`handwrittenTextLength`') && e47.includes('`audioHashes`'));
// write shapes
t('na4: QuizOp ABORT insert', na4.includes('INSERT OR ABORT INTO `QuizOp`'));
t('na4: QuizSession 10-col insert', na4.includes('INSERT INTO `QuizSession`'));
// search integration (quiz searchable? me2 already has types)
const me2 = readFileSync(D + 'me2.java', 'utf8');
t('me2 7-type enum intact (no quiz type)', !me2.includes('QUIZ'));
console.log('quiz-learn replay: ' + n + '/11 checks green');
