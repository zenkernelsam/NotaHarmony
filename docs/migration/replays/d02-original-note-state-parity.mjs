// Phase 1393 — note_state 补齐 NoteStateEntity 全列（round-trip 完整性）。
// 原版证据（decompiled_1.4.2, ca3.java:519）：
//   CREATE TABLE `NoteStateEntity` (`id`,`zoom`,`scrollOffset`,
//     `lastCodeBlockLanguage` TEXT,`zoomViewSourceRect` TEXT,`zoomViewShown`
//     INTEGER,`isTextOnly` INTEGER, PRIMARY KEY(`id`))  — 共 8 列。
//   chb.java:44-47 — 读出 lastCodeBlockLanguage/zoomViewSourceRect/zoomViewShown/
//                    isTextOnly（isNull?null:value）。
//   wmb.java:75/102 — UPDATE zoomViewShown / zoomViewSourceRect。
//   xf3.java:103    — UPDATE isTextOnly。
//   sbe/ten.y       — zoomViewSourceRect 序列化为 "l,t,r,b" 逗号串。
// 断言：note_state 8 列齐全（id/zoom/scroll×2/coordver/lastLang/rect/shown/
// textOnly）、migration 75 三列 ALTER、NoteViewState 全字段、getViewState 读、
// saveViewState REPLACE 前 readPreservedNoteState 保留已存值。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const DB = 'note/src/main/ets/data/DatabaseHelper.ets';
const REPO = 'note/src/main/ets/data/NoteRepositoryImpl.ets';
const MODEL = 'note/src/main/ets/core/model/NoteTypes.ets';

const db = readFileSync(DB, 'utf8');
const repo = readFileSync(REPO, 'utf8');
const model = readFileSync(MODEL, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// === 1. Schema parity：note_state 8 列齐全 ===
check(/DB_VERSION: number = 76/.test(db), 'DB_VERSION bumped to 76');
for (const col of ['zoom REAL', 'scroll_offset_x', 'scroll_offset_y',
  'coordinate_model_version', 'last_code_block_language TEXT',
  'zoom_view_source_rect TEXT DEFAULT NULL', 'zoom_view_shown INTEGER DEFAULT NULL',
  'is_text_only INTEGER DEFAULT NULL']) {
  check(new RegExp(col.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).test(db),
    `note_state column present: ${col}`);
}
{
  const mig = db.match(/75: \[([\s\S]*?)\],?\n\};/);
  check(mig !== null &&
    /ALTER TABLE note_state ADD COLUMN zoom_view_source_rect/.test(mig[1]) &&
    /ALTER TABLE note_state ADD COLUMN zoom_view_shown/.test(mig[1]) &&
    /ALTER TABLE note_state ADD COLUMN is_text_only/.test(mig[1]),
    'migration 75 ALTERs in all three NoteStateEntity parity columns');
}

// === 2. Model parity：NoteViewState 8 字段 ===
for (const field of ['noteId', 'zoom', 'scrollOffsetX', 'scrollOffsetY',
  'coordinateModelVersion', 'lastCodeBlockLanguage', 'zoomViewSourceRect',
  'zoomViewShown', 'isTextOnly']) {
  check(new RegExp(`${field}[?:]`).test(model), `NoteViewState.${field}`);
}

// === 3. Round-trip：getViewState 读全列 ===
for (const col of ['last_code_block_language', 'zoom_view_source_rect',
  'zoom_view_shown', 'is_text_only']) {
  check(repo.includes(`getColumnIndex('${col}')`), `getViewState reads ${col}`);
}

// === 4. saveViewState REPLACE 前保留已存值（undefined→读现值，不丢导入数据）===
check(/readPreservedNoteState\(store, state\.noteId\)/.test(repo),
  'saveViewState reads preserved note_state row before REPLACE');
check(/pick\(state\.lastCodeBlockLanguage/.test(repo) &&
  /pick\(state\.zoomViewSourceRect/.test(repo) &&
  /pick\(state\.zoomViewShown/.test(repo) && /pick\(state\.isTextOnly/.test(repo),
  'all four preserved columns pick incoming-or-kept');
check(/'last_code_block_language':/.test(repo) &&
  /'zoom_view_source_rect':/.test(repo) &&
  /'zoom_view_shown':/.test(repo) && /'is_text_only':/.test(repo),
  'saveViewState bucket writes all four columns');
// 布尔列写 INTEGER 0/1（非 JS boolean）
check(/boolToInt\(pick\(state\.zoomViewShown/.test(repo) &&
  /boolToInt\(pick\(state\.isTextOnly/.test(repo),
  'zoom_view_shown/is_text_only stored as INTEGER 0/1');

console.log(`d02-original-note-state-parity OK — ${n} checks`);
