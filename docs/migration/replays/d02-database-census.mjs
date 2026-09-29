// Phase 1027 — Room database census
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e47 = readFileSync(D + 'e47.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('e47 references NoteBundleMetadataDatabase', e47.includes('NoteBundleMetadataDatabase'));
t('e47 references RawLibraryStateDatabase', e47.includes('RawLibraryStateDatabase'));
t('e47 references ToolboxDatabase', e47.includes('ToolboxDatabase'));
t('e47 references SearchIndexDatabase', e47.includes('SearchIndexDatabase'));
// distinct DAO binder→DB evidence
const wp1 = readFileSync(D + 'wp1.java', 'utf8');
const kq1 = readFileSync(D + 'kq1.java', 'utf8');
const na4 = readFileSync(D + 'na4.java', 'utf8');
t('wp1: insertion adapter', wp1.includes('extends njj') && wp1.includes('ClientOp'));
t('kq1: x5c+wp1 pair', kq1.includes('x5c') && kq1.includes('wp1'));
t('na4: toolbox binder', na4.includes('ToolboxEntity'));
// the four DB names distinct
const names = ['NoteBundleMetadataDatabase','RawLibraryStateDatabase','ToolboxDatabase','SearchIndexDatabase','TranscriptionDatabase','LearnDatabase','NoteAssetDatabase'];
const distinct = names.filter(nm => e47.includes(nm));
t('≥5 distinct DB names in e47', distinct.length >= 5);
// WorkDatabase vendored
t('WorkDatabase vendored', e47.includes('WorkDatabase') || readFileSync(D + 'e47.java','utf8').includes('WorkSpec'));
t('e47 has ≥39 DDL statements', (e47.match(/CREATE TABLE IF NOT EXISTS `/g) || []).length >= 39);
console.log('database-census replay: ' + n + '/10 checks green; DBs: ' + distinct.join(','));
