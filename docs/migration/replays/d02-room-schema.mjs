// Phase 982 — Room schema 全枚举（4 DAO + WorkManager 库表排除）
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const wp1 = readFileSync(`${ROOT}/wp1.java`, 'utf8');
const y93 = readFileSync(`${ROOT}/y93.java`, 'utf8');
const ip1 = readFileSync(`${ROOT}/ip1.java`, 'utf8');
const na4 = readFileSync(`${ROOT}/na4.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// wp1 sync DAO — 7 tables
for (const t of ['ClientOp','ClientNoteUpdate','NoteAsset','PermanentlyDeletedNote','SyncedFolderMetadata','SyncedNoteMetadata','SyncedOpMetadata'])
  ok(wp1.includes('`' + t + '`'), `wp1: ${t}`);

// y93 learn/study DAO — 4 tables
for (const t of ['LearnJob','LearnNoteState','StudyItemsInfo','SummaryEntity'])
  ok(y93.includes('`' + t + '`'), `y93: ${t}`);
ok(/asrHashes/.test(y93), 'y93: asrHashes col (ASR fingerprints)');
ok(/markdown/.test(y93), 'y93: SummaryEntity markdown');

// ip1 folder client — 2 tables
for (const t of ['ClientFolderDelete','ClientFolderEdit'])
  ok(ip1.includes('`' + t + '`'), `ip1: ${t}`);
ok(/childrenHash/.test(ip1) && /idempotencyKey/.test(ip1), 'ip1: childrenHash+idempotencyKey');

// na4 note-state/paper DAO — 5 tables
for (const t of ['BackgroundInfo','IndexedTitle','NoteStateEntity','PaperBackground','QuizSession'])
  ok(na4.includes('`' + t + '`'), `na4: ${t}`);
ok(/zoomViewSourceRect`,`zoomViewShown/.test(na4), 'na4: zoomView cols');
ok(/lastCodeBlockLanguage/.test(na4), 'na4: lastCodeBlockLanguage');
ok(/nullif\(\?, 0\)/.test(na4), 'na4: PaperBackground nullif id');
ok(/lastViewedQuestion`,`questions/.test(na4), 'na4: QuizSession cols');

console.log(`\nroom-schema replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
