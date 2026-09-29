// Phase 1003 — 搜索索引子系统（FTS5 + 双引擎切换）
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const dlc = readFileSync(D + 'dlc.java', 'utf8');
const d6c = readFileSync(D + 'd6c.java', 'utf8');
const vmc = readFileSync(D + 'vmc.java', 'utf8');
const sq1 = readFileSync(D + 'sq1.java', 'utf8');
const e47 = readFileSync(D + 'e47.java', 'utf8');
const kc6 = readFileSync(D + 'kc6.java', 'utf8');
const e49 = readFileSync(D + 'e49.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// dlc FTS5 migration
t('dlc: CREATE VIRTUAL TABLE fts5', dlc.includes('CREATE VIRTUAL TABLE search_fts USING fts5('));
t('dlc: external-content on search_item', dlc.includes("content='search_item'") && dlc.includes("content_rowid='rowid'"));
t('dlc: unicode61 remove_diacritics 2', dlc.includes("tokenize='unicode61 remove_diacritics 2'"));
t('dlc: ai/ad/au triggers', dlc.includes('search_item_ai AFTER INSERT') && dlc.includes('search_item_ad AFTER DELETE') && dlc.includes('search_item_au AFTER UPDATE'));
// d6c queries
t('d6c: engine tag room-fts5', d6c.includes('"room-fts5"'));
t('d6c: FTS MATCH join query', d6c.includes('search_fts JOIN search_item si ON si.rowid = search_fts.rowid WHERE search_fts MATCH ?'));
t('d6c: LIKE fallback escape', d6c.includes("foldedText LIKE ? ESCAPE '\\\\'") || d6c.includes("foldedText LIKE ? ESCAPE"));
// engine switcher
t('vmc: room-fts5 branch deletes SearchIndexDatabase', vmc.includes('ba6.o(string, "room-fts5")') && vmc.includes('deleteDatabase("SearchIndexDatabase")'));
t('vmc: appsearch branch deletes dir', vmc.includes('"appsearch"') && vmc.includes('appsearch'));
t('vmc: rebuild telemetry INDEXING', vmc.includes('Search engine changed; rebuilding index from source') && vmc.includes('yn7.INDEXING'));
// tables + writes
t('e47: search_item schema+unique index', e47.includes('`search_item`') && e47.includes('index_search_item_noteId_type_subId'));
t('e47: FailedIndexedNote indexerVersion', e47.includes('`FailedIndexedNote`') && e47.includes('`indexerVersion` INTEGER'));
t('sq1: search_item UPSERT on conflict', sq1.includes('ON CONFLICT(noteId, type, subId) DO UPDATE'));
t('kc6: two-stage IndexedNote fill', kc6.includes('INSERT INTO IndexedNote (noteId) SELECT noteId FROM IndexedTitle'));
t('e49: chunked changes by processing flag', e49.includes('WHERE noteId = ? AND processing = TRUE ORDER BY chunkIndex'));
console.log('search-index replay: ' + n + '/15 checks green');
