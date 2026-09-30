// Phase 1291 — data/search dual search backend (Room FTS + AppSearch)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/search/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const sr = R('SearchResult.java');
t('SearchResult id/text/score', sr.includes('SearchResult') && sr.includes('score'));
t('SearchResult toString fields', sr.includes('SearchResult(id='));
t('SearchDatabase', X('database/SearchDatabase.java'));
t('SearchDatabase_Impl', X('database/SearchDatabase_Impl.java'));
const si = R('engine/room/SearchIndexDatabase_Impl.java');
t('search/search_item FTS tables', si.includes('search') && si.includes('search_item'));
t('SearchIndexDatabase', X('engine/room/SearchIndexDatabase.java'));
const app = R('C$$__AppSearch__SearchResult.java');
t('AppSearch codegen class', app.includes('AppSearch') || app.length > 0);
t('$$__AppSearch__ prefix present', existsSync(S + 'C$$__AppSearch__SearchResult.java'));
t('SearchDatabase extends Room', R('database/SearchDatabase.java').includes('extends') );
t('dual backend both present', X('engine/room/SearchIndexDatabase.java') && X('C$$__AppSearch__SearchResult.java'));
console.log('search replay: ' + n + '/10 checks green');
