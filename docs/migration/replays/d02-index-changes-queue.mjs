// Phase 1005 — 索引变更队列（l79/c79/两阶段出队）
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const l79 = readFileSync(D + 'l79.java', 'utf8');
const c79 = readFileSync(D + 'c79.java', 'utf8');
const i79 = readFileSync(D + 'i79.java', 'utf8');
const e49 = readFileSync(D + 'e49.java', 'utf8');
const wp1 = readFileSync(D + 'wp1.java', 'utf8');
const la4 = readFileSync(D + 'la4.java', 'utf8');
const ya9 = readFileSync(D + 'ya9.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// c79 entity
t('c79: 8-field entity', c79.includes('public final ttf a') && c79.includes('public final List b') && c79.includes('public final List c') && c79.includes('public final List d'));
t('c79: 3 bools + int', /public final boolean e;[\s\S]{0,60}public final boolean f;[\s\S]{0,60}public final boolean g;[\s\S]{0,60}public final int h;/.test(c79));
// l79 DAO
t('l79: x5c db + wp1 binder', l79.includes('public final x5c a') && l79.includes('new wp1(this, 5)'));
t('l79.f: static enqueue tx', /static Object f\(l79 l79Var, c79 c79Var, ff2/.test(l79));
t('l79.a: (c79,n8e) merge path', /Object a\(c79 c79Var, n8e n8eVar\)/.test(l79));
// wp1 insert SQL
t('wp1: INSERT OR ABORT 8-col', wp1.includes('INSERT OR ABORT INTO `NoteIndexableChanges`') && wp1.includes('`chunkIndex`'));
// two-phase dequeue
t('i79: DISTINCT pending notes (FALSE)', i79.includes('SELECT DISTINCT noteId FROM NoteIndexableChanges WHERE processing = FALSE'));
t('i79: DISTINCT claimed notes (TRUE)', i79.includes('SELECT DISTINCT noteId FROM NoteIndexableChanges WHERE processing = TRUE'));
t('i79: ordered chunks by chunkIndex', i79.includes('processing = TRUE ORDER BY chunkIndex'));
t('e49: per-note chunk scan', e49.includes('WHERE noteId = ? AND processing = TRUE ORDER BY chunkIndex'));
// failure ledger
t('la4: FailedIndexedNote{noteId,errorClass,timestamp}', la4.includes('public final ttf a') && la4.includes('public final String b') && la4.includes('public final long c'));
t('la4: indexerVersion=2 constant', la4.includes('indexerVersion=2'));
// batch cleanup
t('ya9: batch DELETE noteId IN', ya9.includes('DELETE FROM NoteIndexableChanges WHERE noteId IN ('));
// entity users
t('nr1 references l79', readFileSync(D + 'nr1.java', 'utf8').includes('l79'));
console.log('index-changes-queue replay: ' + n + '/14 checks green');
