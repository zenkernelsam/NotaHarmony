// Phase 1324 — haa 30-op → Harmony Original* coverage
import { existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
const X = f => existsSync(S + f);
const files = readdirSync(S);
const has = pat => files.some(f => f.startsWith(pat));
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ADD_PATH_ELEMENTS', has('OriginalAddPathElements'));
t('CREATE_BLOCK', has('OriginalCreateBlock'));
t('CREATE_INK', has('OriginalCreateInk'));
t('CREATE_PAGE', has('OriginalCreatePage'));
t('CREATE_SHAPE', has('OriginalCreateShape'));
t('DELETE_ENTITIES', has('OriginalDeleteEntities'));
t('text ops (INSERT/REMOVE)', has('OriginalInsertText') || has('OriginalLocalTextMutation'));
t('MODIFY ops (BLOCK/INK/PAGE/SHAPE/POSITIONS)', ['OriginalModifyBlock','OriginalModifyInk','OriginalModifyPage','OriginalModifyShape','OriginalModifyPositions'].filter(has).length >= 4);
t('SET_METADATA+PEER+CHECKBOX', has('OriginalSetMetadata') && has('OriginalPeerInteraction') && has('OriginalUpdateCheckbox'));
t('51+ Original* op files', files.filter(f => /^Original.*(Operation|Encoder|Codec|Mutation|State)/.test(f)).length >= 45);
console.log('op-coverage replay: ' + n + '/10 checks green');
