// Phase 1318 — Harmony persistence (RdbStore + repos + op store)
import { readFileSync, existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const dm = readFileSync(S + 'DatabaseManager.ets', 'utf8');
t('RdbStore', dm.includes('relationalStore') && dm.includes('RdbStore'));
t('getRdbStore', dm.includes('getRdbStore'));
t('security level', dm.includes('SecurityLevel'));
t('foreign_keys pragma', dm.includes('foreign_keys'));
t('local_editor_identity site-id', dm.includes('local_editor_identity'));
t('DDL executeSql', dm.includes('executeSql'));
t('repos', X('NoteRepositoryImpl.ets') && X('FolderRepositoryImpl.ets') && X('PageRepositoryImpl.ets'));
t('OpStoreImpl op log', X('OpStoreImpl.ets'));
const stores = readdirSync(S).filter(f => /Store\.ets$/.test(f));
t('10+ Store files', stores.length >= 10);
t('AssetRepositoryImpl', X('AssetRepositoryImpl.ets'));
console.log('persistence replay: ' + n + '/10 checks green');
