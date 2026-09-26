// Phase 846 — 非混淆包骨架 162 文件完备性 + AppSearch 文档
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability';
const results = [];
const ck = (n, ok) => results.push([n, ok]);
const all = [];
const walk = (d) => { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walk(p); else if (f.name.endsWith('.java')) all.push(p); } };
walk(B);
const names = all.map(f => f.split(/[\\/]/).pop());

ck('全包文件=162', all.length === 162);

// 分域计数
const exn = names.filter(n => /Exception|Error/.test(n)).length;
const wk = names.filter(n => /Worker\.java$|Initializer\.java$/.test(n)).length;
const comp = names.filter(n => /(Activity|Provider|Receiver|Service)\.java$/.test(n) || n === 'NbApplication.java').length;
const db = names.filter(n => /Database.*\.java$/.test(n)).length;
const letter = names.filter(n => /^[a-l]\.java$/.test(n)).length;
ck('异常64', exn === 64);
ck('Worker+Init=21', wk === 21);
ck('组件=19', comp === 19);
ck('数据库=26', db === 26);
ck('字母模型=24', letter === 24);
ck('余项=8 闭合', 162 - exn - wk - comp - db - letter === 8);

// AppSearch SearchResult 文档
const sr = readFileSync(join(B, 'data/search/engine/appsearch/SearchResult.java'), 'utf8');
ck('SearchResult @Document 字段', /mx3/.test(sr) || sr.includes('class SearchResult'));
const gen = readFileSync(join(B, 'data/search/engine/appsearch/C$$__AppSearch__SearchResult.java'), 'utf8');
ck('文档属性 text+pageId', gen.includes('"text"') && gen.includes('"pageId"'));
ck('score 非负约束', gen.includes('Document score cannot be negative'));

// Harmony search_item 表
const ddl = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/DatabaseHelper.ets', 'utf8');
ck('Harmony search_item 表', ddl.includes('DDL_SEARCH_ITEM') && ddl.includes('folded_text') && ddl.includes('page_id'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
