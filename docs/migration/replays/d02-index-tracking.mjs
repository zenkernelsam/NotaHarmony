// Phase 1024 — index-tracking trio
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e47 = readFileSync(D + 'e47.java', 'utf8');
const kc6 = readFileSync(D + 'kc6.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('IndexedTitle: (noteId,title)', e47.includes('`IndexedTitle`') && e47.includes('`title` TEXT NOT NULL') && /IndexedTitle.*PRIMARY KEY\(`noteId`\)/.test(e47));
t('IndexedNote: noteId only', e47.includes('`IndexedNote`') && /IndexedNote.*PRIMARY KEY\(`noteId`\)/.test(e47));
t('FailedIndexedNote: error cols', e47.includes('`FailedIndexedNote`') && e47.includes('`errorClass` TEXT') && e47.includes('`timestamp` INTEGER') && e47.includes('`indexerVersion` INTEGER'));
t('FailedIndexedNote: noteId PK', /FailedIndexedNote.*PRIMARY KEY\(`noteId`\)/.test(e47));
t('two-stage INSERT SELECT', kc6.includes('INSERT INTO IndexedNote (noteId) SELECT noteId FROM IndexedTitle'));
t('indexerVersion=2 const', readFileSync(D + 'la4.java', 'utf8').includes('indexerVersion=2'));
t('DROPs present', e47.includes('DROP TABLE IF EXISTS `IndexedTitle`') && e47.includes('DROP TABLE IF EXISTS `IndexedNote`') && e47.includes('DROP TABLE IF EXISTS `FailedIndexedNote`'));
// noteIndexableChanges joins
t('NoteIndexableChanges: chunkIndex', e47.includes('`chunkIndex`') && e47.includes('`processing`'));
const l79 = readFileSync(D + 'l79.java', 'utf8');
const i79 = readFileSync(D + 'i79.java', 'utf8');
t('l79 DAO class', /final class l79/.test(l79));
t('i79: chunkIndex queries', i79.includes('chunkIndex'));
t('search writes noteId', kc6.includes('search_item') || kc6.includes('IndexedTitle'));
console.log('index-tracking replay: ' + n + '/11 checks green');
