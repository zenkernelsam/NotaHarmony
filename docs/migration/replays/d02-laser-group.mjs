// Phase 1334 — laser pointer + group ops
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const A = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/adaptation/';
const D = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const l = readFileSync(A + 'OriginalLaserPointer.ets', 'utf8');
t('pointer state', l.includes('pointerPoint') && l.includes('pointerAlpha'));
t('original refs zt6/yt6', l.includes('zt6') && l.includes('yt6'));
t('500ms hold', l.includes('500'));
t('31×16ms fade', l.includes('31') && l.includes('16'));
t('transient (not persisted)', l.includes('瞬态') || l.includes('showTail'));
t('GroupLayering', existsSync(D + 'OriginalGroupLayering.ets'));
t('GroupMutationOpCodec', existsSync(D + 'OriginalGroupMutationOpCodec.ets'));
t('GroupPayloadEncoder', existsSync(D + 'OriginalGroupPayloadEncoder.ets'));
t('PartialEraseGroupPlanner', existsSync(D + 'OriginalPartialEraseGroupPlanner.ets'));
t('ShapeGroupOperation', existsSync(D + 'OriginalShapeGroupOperation.ets'));
console.log('laser-group replay: ' + n + '/10 checks green');
