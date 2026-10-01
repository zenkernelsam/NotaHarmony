// Phase 1392 — note_state.last_code_block_language 每笔记代码块语言记忆。
// 原版证据（decompiled_1.4.2）：
//   ca3.java:519  — NoteStateEntity CREATE TABLE 含 lastCodeBlockLanguage TEXT。
//   r4a.java:70   — 原版迁移：ALTER TABLE NoteStateEntity ADD COLUMN
//                   lastCodeBlockLanguage TEXT DEFAULT NULL。
//   chb.java:44   — SELECT 读 lastCodeBlockLanguage（isNull?null:String）。
//   ws3.java:277  — SELECT lastCodeBlockLanguage FROM NoteStateEntity WHERE id=?
//                   （按笔记读取用于恢复）。
//   ya8.java:34   — CODE_BLOCK toggle 需 lastCodeBlockLanguageId restore：
//                   新建代码块默认恢复本笔记上一次使用的语言而非 plaintext。
//   e83/f83.java  — INSERT/UPDATE 整行写 lastCodeBlockLanguage 列。
// 断言：列+migration74+全链路透传+restore-on-new-block+选择回传持久化。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const DB = 'note/src/main/ets/data/DatabaseHelper.ets';
const REPO = 'note/src/main/ets/data/NoteRepositoryImpl.ets';
const IFACE = 'note/src/main/ets/data/RepositoryInterfaces.ets';
const MODEL = 'note/src/main/ets/core/model/NoteTypes.ets';
const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const OVERLAY = 'note/src/main/ets/ui/components/TextBlockOverlay.ets';

const db = readFileSync(DB, 'utf8');
const repo = readFileSync(REPO, 'utf8');
const iface = readFileSync(IFACE, 'utf8');
const model = readFileSync(MODEL, 'utf8');
const view = readFileSync(VIEW, 'utf8');
const overlay = readFileSync(OVERLAY, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// === 1. Schema parity（r4a.java:70 同款迁移 + canonical DDL）===
check(/DB_VERSION: number = 76/.test(db), 'DB_VERSION bumped to 76');
check(/last_code_block_language TEXT DEFAULT NULL/.test(db),
  'note_state.last_code_block_language column (NoteStateEntity.lastCodeBlockLanguage)');
{
  const mig = db.match(/74: \[([\s\S]*?)\],?\n\};/);
  check(mig !== null &&
    /ALTER TABLE note_state ADD COLUMN last_code_block_language TEXT DEFAULT NULL/.test(mig[1]),
    'migration 74 ALTERs in last_code_block_language');
}

// === 2. Model + repository round-trip ===
check(/lastCodeBlockLanguage\?:\s*string \| null/.test(model),
  'NoteViewState.lastCodeBlockLanguage optional field');
check(/getColumnIndex\('last_code_block_language'\)/.test(repo),
  'getViewState reads last_code_block_language');
check(/'last_code_block_language':/.test(repo) &&
  /pick\(state\.lastCodeBlockLanguage/.test(repo),
  'saveViewState writes last_code_block_language');
// preserve-on-undefined（saveViewportState 不带字段 → 保留已存值，不被 REPLACE 清掉）
check(/state\.lastCodeBlockLanguage === undefined[\s\S]{0,160}readPreservedNoteState/.test(repo),
  'saveViewState preserves existing language when field is undefined');
check(/async saveLastCodeBlockLanguage\(noteId: string, lang: string \| null\)/.test(repo),
  'saveLastCodeBlockLanguage dedicated setter');
check(/saveLastCodeBlockLanguage\(noteId: string, lang: string \| null\): Promise<void>/.test(iface),
  'repository interface exposes saveLastCodeBlockLanguage');

// === 3. View wiring（载入 + 回传持久化）===
check(/this\.lastCodeBlockLanguage = state\?\.lastCodeBlockLanguage \?\? null/.test(view),
  'NoteCanvasView loads lastCodeBlockLanguage from getViewState');
check(/lastCodeBlockLanguage: this\.lastCodeBlockLanguage/.test(view),
  'NoteCanvasView passes lastCodeBlockLanguage to TextBlockOverlay');
check(/onCodeLanguageSelected:[\s\S]{0,60}persistCodeBlockLanguage\(lang\)/.test(view),
  'onCodeLanguageSelected callback persists via persistCodeBlockLanguage');
check(/saveLastCodeBlockLanguage\(this\.noteId, lang\)/.test(view),
  'persistCodeBlockLanguage writes via repository');

// === 4. Overlay restore + write-back（ya8.java:34）===
check(/@Prop lastCodeBlockLanguage: string \| null/.test(overlay),
  'TextBlockOverlay lastCodeBlockLanguage prop');
check(/onCodeLanguageSelected: \(lang: string \| null\) => void/.test(overlay),
  'TextBlockOverlay onCodeLanguageSelected callback');
check(/decorator === 5 && this\.lastCodeBlockLanguage !== null[\s\S]{0,220}next\.programmingLanguage = this\.lastCodeBlockLanguage/
  .test(overlay),
  'new code block restores lastCodeBlockLanguage as programmingLanguage default');
check(/onCodeLanguageSelected\(next\.programmingLanguage \?\? null\)/.test(overlay),
  'setCodeLanguage reports chosen language (plaintext→null) for persistence');

console.log(`d02-original-code-block-language-restore OK — ${n} checks`);
