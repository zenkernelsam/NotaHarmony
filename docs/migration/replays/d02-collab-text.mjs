// Phase 1333 — collaborative text ops (INSERT/REMOVE/REVIVE_CHARS)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const m = readFileSync(S + 'OriginalLocalTextMutation.ets', 'utf8');
t('StoredCharacter tombstone', m.includes('StoredCharacter') && m.includes('visible'));
t('remove→visible=false', m.includes('visible = false'));
t('revive→visible=true', m.includes('visible = true'));
t('predict insertion identity', m.includes('predictOriginalTextInsertionIdentity'));
t('preview mutation', m.includes('previewOriginalLocalTextMutation'));
t('per-char identity key', m.includes('identityKey'));
t('InsertTextOperation', existsSync(S + 'OriginalInsertTextOperation.ets'));
t('PageOperationApplier', existsSync(S + 'OriginalPageOperationApplier.ets'));
t('RichTextStyle op', existsSync(S + 'OriginalRichTextStyleOperation.ets'));
t('text payload encoder', existsSync(S + 'OriginalInsertTextPayloadEncoder.ets'));
console.log('collab-text replay: ' + n + '/10 checks green');
