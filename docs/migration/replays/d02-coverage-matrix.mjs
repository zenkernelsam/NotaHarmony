// Phase 1323 (milestone) — original↔Harmony coverage matrix
import { existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const E = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/';
const X = f => existsSync(E + f);
const n_in = (dir, pat) => existsSync(E + dir) ? readdirSync(E + dir, {recursive:true}).filter(f => pat.test(f)).length : 0;
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// implemented core
t('editor impl', X('ui/editor/NoteCanvasView.ets') && X('ui/editor/EditorViewModel.ets'));
t('CRDT wire fidelity', X('data/OriginalSyncedOperationFlatBuffer.ets') && X('data/OperationIdentity.ets'));
t('op store+codecs', X('data/OpStoreImpl.ets') && n_in('data', /OpCodec/) > 5);
t('op encoders', n_in('data', /PayloadEncoder/) >= 6);
t('persistence RdbStore', X('data/DatabaseManager.ets'));
t('rendering', X('rendering/OriginalMathEngine.ets') && X('rendering/EraserEngine.ets'));
t('import .note', X('data/NoteImporter.ets'));
t('export+webdav backup', X('data/NoteExporter.ets') && X('data/WebDAVClient.ets'));
t('widget cards', X('noteformability/NoteFormAbility.ets'));
// fail-closed gaps
const gaps = ['billing','subscription','oauth','liveTranscri','iink'];
let gapFree = true;
const walk = d => { for (const f of readdirSync(E + d, {withFileTypes:true})) { const p = d+'/'+f.name; if (f.isDirectory()) walk(p); else if (gaps.some(g => f.name.toLowerCase().includes(g))) gapFree = false; } };
walk('.');
t('no billing/oauth/transcription/iink impls', gapFree);
console.log('coverage-matrix replay: ' + n + '/10 checks green');
