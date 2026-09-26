// Phase 853 — Room DDL 语句级登记：CREATE TABLE/INDEX 宿主分布 +
// 迁移体 _new_* 重建模式 + vendor DDL 隔离 + Harmony RDB 对照。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/';
const app = f => readFileSync(D + f + '.java', 'utf8');
const tables = s => [...s.matchAll(/CREATE TABLE IF NOT EXISTS `([^`]+)`/g)].map(m => m[1]);
const indexes = s => (s.match(/CREATE INDEX/g) || []).length;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 12 个含 DDL 的宿主文件中应用侧 DDL 汇总 ---
const ca3 = app('ca3');
const ca3Tables = new Set(tables(ca3));
check(ca3Tables.size === 54, `ca3 应用+WM 表数 (got ${ca3Tables.size})`);
check(indexes(ca3) === 18, `ca3 CREATE INDEX 数 (got ${indexes(ca3)})`);
for (const t of ['QuizSession', 'ClientOp', 'SyncedFolderMetadata',
  'InkPageRecognizer', 'ToolboxEntity', 'transcription_segments',
  'CustomTemplate', 'PendingLike', 'NoteAsset', 'DraftNote'])
  check(ca3Tables.has(t), `ca3 含 ${t}`);

// --- 迁移体重建模式 ---
const zmb = app('zmb'), r4a = app('r4a'), yf1 = app('yf1'), wf1 = app('wf1'), fgf = app('fgf');
check(tables(yf1).includes('calendarSelections') && tables(yf1).includes('syllabusCourses'),
  'yf1 = Calendar 迁移体');
check(tables(wf1).includes('syllabusCourses'), 'wf1 = syllabus 建表');
check(zmb.includes('ToolStateEntity_new') && r4a.includes('_new_WorkSpec'),
  'zmb/r4a 含 _new_* 重建模式');
check(tables(fgf).includes('IndexedNote') && tables(fgf).includes('FailedIndexedNote'),
  'fgf = Search 迁移体');

// --- vendor DDL 隔离（非应用面）---
const vendor = { xbf: 'events', oal: 'apps', cye: 'records', ao9: 'anonymous_people' };
for (const [f, t] of Object.entries(vendor))
  check(app(f).includes(`CREATE TABLE`) && app(f).includes(t), `vendor ${f} 含 ${t}`);

// --- Harmony RDB 对照 ---
const helper = readFileSync('note/src/main/ets/data/DatabaseHelper.ets', 'utf8');
const hTables = new Set([...helper.matchAll(/CREATE TABLE IF NOT EXISTS (\w+)/g)].map(m => m[1]));
check(hTables.size >= 65, `Harmony RDB 表数≥65 (got ${hTables.size})`);
for (const t of ['note_meta', 'folder', 'note_state', 'operation_log',
  'editor_toolbox_state', 'search_item', 'note_asset',
  'permanently_deleted_note', 'synced_operation_inbox',
  'original_ink_state', 'favorite_color_well'])
  check(hTables.has(t), `Harmony 含 ${t}`);
// fail-closed：原版学习/日历/画廊/转写域表在 Harmony 无对应
for (const t of ['QuizSession', 'syllabusCourses', 'PendingLike', 'transcriptions'])
  check(!hTables.has(t), `Harmony fail-closed 无 ${t}`);

console.log(`${n}/${n} checks passed`);
