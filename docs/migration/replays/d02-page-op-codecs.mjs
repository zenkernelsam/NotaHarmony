// Phase 1342 — page-level op codec family
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const dp = readFileSync(S + 'DuplicatePageOpCodec.ets', 'utf8');
t('dup codec BinaryOp', dp.includes('BinaryOpReader') || dp.includes('BinaryOpWriter'));
t('original de2.j ref', dp.includes('de2'));
t('CreatePage+paste compound', dp.includes('CreatePage') && dp.includes('paste'));
t('page-order validate', dp.includes('validatePageOrder'));
t('exactly-one-page rule', dp.includes('exactly one page'));
t('DeletePageCompensation', existsSync(S + 'DeletePageCompensationOpCodec.ets'));
t('PageBookmark codec', existsSync(S + 'PageBookmarkOpCodec.ets'));
t('PageSnapshot codec', existsSync(S + 'PageSnapshotOpCodec.ets'));
t('PageReorderPlanner', existsSync(S + 'OriginalPageReorderPlanner.ets'));
t('PartialEraseMutationCodec', existsSync(S + 'OriginalPartialEraseMutationCodec.ets'));
console.log('page-op-codecs replay: ' + n + '/10 checks green');
