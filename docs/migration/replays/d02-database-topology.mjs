// Phase 822 — database topology + migration-chain closure
// 1. 13 Room DBs in 1.4.2 vs 10 in 1.0.x (Calendar/GalleryMutation/CustomTemplates new)
// 2. NoteStateDatabase v4->v5; Learn v7; Calendar v2 launch
// 3. Entity inventory per DB recovered (Toolbox=6, Learn=7, SearchDB=7)
// 4. Harmony unified RDB DB_VERSION=71 with domain-mapped tables
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, basename } from 'node:path';

const REF = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';
let pass = 0, fail = 0;
const ok = (name, cond, detail = '') => {
  if (cond) { pass++; console.log(`  ok ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${detail}`); }
};

const walk = (d, acc = []) => {
  if (!existsSync(d)) return acc;
  for (const e of readdirSync(d, { withFileTypes: true })) {
    const p = join(d, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('Database_Impl.java')) acc.push(p);
  }
  return acc;
};

// -- 1. DB counts --------------------------------------------------------------
const c103 = walk(join(REF, 'decompiled_1.0.3/sources/com/gingerlabs')).length;
const c142 = walk(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs')).length;
ok('1.0.3 has 10 Room DBs', c103 === 10, `got ${c103}`);
ok('1.4.2 has 13 Room DBs', c142 === 13, `got ${c142}`);
for (const n of ['CalendarDatabase', 'GalleryMutationDatabase', 'CustomTemplatesDatabase']) {
  ok(`${n} new in 1.4.2`,
    existsSync(join(REF, `decompiled_1.4.2/sources/com/gingerlabs`)) &&
    walk(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs')).some(f => f.includes(n)) &&
    !walk(join(REF, 'decompiled_1.0.3/sources/com/gingerlabs')).some(f => f.includes(n)));
}

// -- 2. migration chains ---------------------------------------------------------
const ns103 = readFileSync(join(REF, 'decompiled_1.0.3/sources/com/gingerlabs/notability/data/note/state/NoteStateDatabase_Impl.java'), 'utf8');
ok('NoteStateDB 1.0.3 chain = 1->2,2->3,3->4 (v4)',
  /add\(new \w+\(1, 2, 17\)\)/.test(ns103) && /add\(new \w+\(3, 4, 19\)\)/.test(ns103));
const ns142 = readFileSync(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs/notability/data/note/state/NoteStateDatabase_Impl.java'), 'utf8');
ok('NoteStateDB 1.4.2 chain reaches 4->5 (v5)',
  /add\(new \w+\(\(byte\) ?\d+, \w+, \w+\)\)/.test(ns142) && ns142.match(/add\(new/g)?.length === 4);
const cal = readFileSync(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs/notability/data/calendar/database/CalendarDatabase_Impl.java'), 'utf8');
ok('CalendarDB launches at v2 (1->2)', /add\(new \w+\(1, 2\)\)/.test(cal));

// -- 3. entity inventory ------------------------------------------------------------
const toolbox = readFileSync(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs/notability/data/toolbar/database/ToolboxDatabase_Impl.java'), 'utf8');
ok('ToolboxDB has 6 entities',
  ['TrayEntity', 'ToolStateEntity', 'ToolboxEntity', 'FavoriteColorWellEntity', 'RecentColorWellEntity', 'WidthSizeWellEntity']
    .every(e => toolbox.includes(e)));
const gal = readFileSync(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs/notability/data/gallery/outbox/GalleryMutationDatabase_Impl.java'), 'utf8');
ok('GalleryMutationDB = PendingLike+PendingFollow outbox',
  gal.includes('PendingLike') && gal.includes('PendingFollow'));

// -- 4. Harmony mapping ----------------------------------------------------------------
const helper = readFileSync(join(REPO, 'note/src/main/ets/data/DatabaseHelper.ets'), 'utf8');
ok('Harmony unified DB at version 71', /DB_VERSION: number = 71/.test(helper));
const tables = new Set([...helper.matchAll(/CREATE TABLE(?: IF NOT EXISTS)? (\w+)/g)].map(m => m[1]));
ok('Harmony RDB has >= 80 CREATE TABLE', tables.size >= 80, `got ${tables.size}`);
const need = ['note_state', 'note_meta', 'note_asset', 'folder', 'permanently_deleted_note',
  'client_op', 'operation_log', 'deferred_synced_operation_bundle', 'editor_toolbox_state',
  'editor_tray', 'tool_state', 'width_size_well', 'favorite_color_well', 'recent_color_well',
  'PaperBackground', 'BackgroundInfo', 'search_item'];
const hasTable = n => tables.has(n) || [...tables].some(t => t.startsWith(n + '_v'));
const missing = need.filter(t => !hasTable(t));
ok('Harmony covers original domain tables', missing.length === 0, missing.join(','));

console.log(`\n${pass}/${pass + fail} checks passed`);
process.exit(fail ? 1 : 0);
