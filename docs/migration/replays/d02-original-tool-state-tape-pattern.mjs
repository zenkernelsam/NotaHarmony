// Phase 576 — original Room schema per-table comparison, actionable divergence:
// original ToolStateEntity (decompiled_1.0.3/sources/defpackage/e47.java) carries
//   `tapePattern` INTEGER DEFAULT NULL
// between selectedWidthSizeWellIndex and selectionIsFreehand — the REVIEW/tape
// tool's persisted pattern survives restarts. Harmony tool_state lacked the
// column; v71 adds it (fresh DDL + ALTER TABLE migration).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const DB = 'note/src/main/ets/data/DatabaseHelper.ets';
const REPO = 'note/src/main/ets/data/ToolRepositoryImpl.ets';
const TYPES = 'note/src/main/ets/core/model/BrushTypes.ets';
const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';

const db = readFileSync(DB, 'utf8');
const repo = readFileSync(REPO, 'utf8');
const types = readFileSync(TYPES, 'utf8');
const vm = readFileSync(VM, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- schema version + v71 migration ---
check(/DB_VERSION: number = 71/.test(db), 'DB_VERSION = 71');
const mig71 = db.slice(db.indexOf('  71: ['), db.indexOf('};', db.indexOf('  71: [')));
check(mig71.includes('ALTER TABLE tool_state ADD COLUMN tape_pattern INTEGER'),
  'v71 migrates tool_state.tape_pattern');

// --- DDL_TOOL_STATE: nullable column, original position (after selectedWidthSizeWellIndex,
//     before selectionIsFreehand), no NOT NULL / DEFAULT on the column itself ---
const ddlStart = db.indexOf('export const DDL_TOOL_STATE');
const ddlEnd = db.indexOf('`;', ddlStart);
const ddl = db.slice(ddlStart, ddlEnd);
const tapeLine = ddl.split('\n').find((l) => l.trim().startsWith('tape_pattern'));
check(tapeLine !== undefined, 'tool_state DDL declares tape_pattern');
check(/tape_pattern INTEGER,?\s*$/.test(tapeLine.trim()),
  'tape_pattern is plain nullable INTEGER (original DEFAULT NULL)');
check(!/NOT NULL/.test(tapeLine), 'tape_pattern nullable');
check(ddl.indexOf('tape_pattern') > ddl.indexOf('selected_width_well_index'),
  'tape_pattern after selected_width_well_index');
check(ddl.indexOf('tape_pattern') < ddl.indexOf('selection_is_freehand'),
  'tape_pattern before selection_is_freehand');

// --- ToolState model ---
check(/tapePattern\?: TapePattern \| null/.test(types),
  'ToolState.tapePattern optional-nullable TapePattern');
check(types.includes("import { InkStyle, TapePattern } from './StrokeTypes'"),
  'BrushTypes imports TapePattern');

// --- repository round trip ---
check(/isColumnNull\(resultSet\.getColumnIndex\('tape_pattern'\)\)/.test(repo),
  'rowToState NULL-checks tape_pattern');
check(/getLong\(resultSet\.getColumnIndex\('tape_pattern'\)\) as TapePattern/.test(repo),
  'rowToState maps non-NULL to TapePattern');
check(/'tape_pattern': state\.tapePattern \?\? null/.test(repo),
  'toBucket writes tape_pattern (null default)');
check(/tapePattern: state\.tapePattern \?\? null/.test(repo),
  'cloneState carries tapePattern');
// The VM keeps its own cloneState for snapshots/backfill/updateActiveState —
// without the field, any tool mutation would silently erase the pattern.
const vmClone = vm.slice(vm.indexOf('private cloneState(state: ToolState)'));
check(vmClone.includes('tapePattern: state.tapePattern ?? null'),
  'EditorViewModel.cloneState carries tapePattern');

// --- adjacent schema-parity invariants re-verified in this phase ---
// FavoriteColorWellEntity / WidthSizeWellEntity / RecentColorWellEntity column sets
// match e47.java verbatim (id PK autoincrement + per-tool/per-index/value).
const fav = db.slice(db.indexOf('DDL_FAVORITE_COLOR_WELL'),
  db.indexOf('`;', db.indexOf('DDL_FAVORITE_COLOR_WELL')));
check(fav.includes('id INTEGER PRIMARY KEY AUTOINCREMENT') &&
  fav.includes('tool_type INTEGER NOT NULL') && fav.includes('color INTEGER NOT NULL') &&
  fav.includes('tray_index INTEGER NOT NULL'),
  'favorite_color_well mirrors FavoriteColorWellEntity');
const rec = db.slice(db.indexOf('DDL_RECENT_COLOR_WELL'),
  db.indexOf('`;', db.indexOf('DDL_RECENT_COLOR_WELL')));
check(rec.includes('color INTEGER NOT NULL') && rec.includes('timestamp INTEGER NOT NULL'),
  'recent_color_well mirrors RecentColorWellEntity');
// PaperBackground keeps original camelCase columns (e47.java:371).
const paper = db.slice(db.indexOf('DDL_ORIGINAL_PAPER_BACKGROUND'),
  db.indexOf('`;', db.indexOf('DDL_ORIGINAL_PAPER_BACKGROUND')));
check(paper.includes('paperSize INTEGER NOT NULL') &&
  paper.includes('paperOrientation TEXT NOT NULL') &&
  paper.includes('legacyPaperIndex INTEGER') && paper.includes('hasOptions INTEGER NOT NULL'),
  'PaperBackground keeps original camelCase columns');
// search_item keeps the original UNIQUE(noteId,type,subId) constraint.
const si = db.slice(db.indexOf('DDL_SEARCH_ITEM'),
  db.indexOf('`;', db.indexOf('DDL_SEARCH_ITEM')));
check(/UNIQUE\(note_id, type, sub_id\)/.test(si),
  'search_item preserves index_search_item_noteId_type_subId uniqueness');

console.log(`D02_ORIGINAL_TOOL_STATE_TAPE_PATTERN_OK TOTAL=${n} FAILED=0`);
