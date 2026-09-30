// Phase 1308 — op-taxonomy divergence (Harmony OpTypes vs haa)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/model/OpTypes.ets';
const d = readFileSync(S, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ORIGINAL_ bridge ops', d.includes('ORIGINAL_CREATE_PAGE') && d.includes('ORIGINAL_INSERT_TEXT'));
t('ORIGINAL_SET_METADATA', d.includes('ORIGINAL_SET_METADATA'));
t('ORIGINAL_MODIFY ops', d.includes('ORIGINAL_MODIFY_TEXT_STYLE'));
t('UNDO as op (divergence)', d.includes('UNDO'));
t('REDO as op', d.includes('REDO'));
t('ERASE ops', d.includes('ERASE_PARTIAL') && d.includes('ERASE_WHOLE'));
t('element-granularity ops', d.includes('INSERT_ELEMENTS') || d.includes('REMOVE_TEXT'));
t('PAGE_SNAPSHOT', d.includes('PAGE_SNAPSHOT'));
t('REORDER_PAGES', d.includes('REORDER_PAGES'));
t('op codec exists', existsSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/BinaryOpCodec.ets'));
console.log('op-taxonomy replay: ' + n + '/10 checks green');
