// Phase 854 — Room DAO SQL 契约层：宿主分布、ws3 元数据投影
// CTE、opId 打包语义、Harmony 等价实现。
import { readFileSync, readdirSync } from 'node:fs';
import assert from 'node:assert';

const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/';
const app = f => readFileSync(D + f + '.java', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 宿主分布：67 个纯 DAO 宿主（剔除 853 登记的 12 个 DDL 宿主）---
const APP_TABLES = ['QuizSession', 'QuizOp', 'LearnNoteState', 'SummaryEntity',
  'LearnJob', 'StudyItemsInfo', 'CompletedQuizSession', 'NoteAsset',
  'SyncedOpMetadata', 'ClientOp', 'NoteIndexableChanges', 'DeferredSyncedOps',
  'DraftNote', 'UploadRejection', 'NoteStateEntity', 'SyncedNoteMetadata',
  'ClientNoteUpdate', 'PermanentlyDeletedNote', 'SyncedFolderMetadata',
  'ClientFolderEdit', 'ClientFolderDelete', 'IndexedTitle', 'IndexedNote',
  'FailedIndexedNote', 'SearchIndexSyncState', 'FailedInkPage',
  'SearchIndexPendingUpload', 'InkPageRecognizer', 'PaperBackground',
  'BackgroundInfo', 'TemplatePaperInfo', 'FavoritePaperTemplate',
  'RecentPaperTemplate', 'RecentGalleryTemplate', 'PaperTemplateUsage',
  'TrayEntity', 'FavoriteColorWellEntity', 'WidthSizeWellEntity',
  'ToolStateEntity', 'ToolboxEntity', 'RecentColorWellEntity',
  'transcriptions', 'transcription_segments', 'calendarSelections',
  'calendarDismissedEvents', 'syllabusCourses', 'syllabusEvents',
  'PendingLike', 'PendingFollow', 'CustomTemplate',
  'PendingTemplateDeletion', 'search_item'];
const DDL_HOSTS = new Set(['ca3', 'wf1', 'yf1', 'r4a', 'zmb', 'fgf',
  's4a', 'xbf', 'oal', 'cye', 'ao9', 'ac3']);
const sqlHosts = readdirSync(D).filter(f => f.endsWith('.java'))
  .filter(f => readFileSync(D + f, 'utf8').includes('SELECT '));
const daoHosts = sqlHosts.filter(f => !DDL_HOSTS.has(f.replace('.java', '')))
  .filter(f => {
    const s = readFileSync(D + f, 'utf8');
    return APP_TABLES.some(t => s.includes(`FROM ${t}`) || s.includes(`INTO ${t}`) ||
      s.includes(`UPDATE ${t}`) || s.includes(`JOIN ${t}`));
  });
check(sqlHosts.length === 102, `SELECT 宿主总数 (got ${sqlHosts.length})`);
check(daoHosts.length === 67, `应用 DAO 宿主数 (got ${daoHosts.length})`);
const appStmts = daoHosts.reduce((a, f) =>
  a + (readFileSync(D + f, 'utf8').match(/SELECT |UPDATE |DELETE FROM|INSERT INTO/g) || []).length, 0);
check(appStmts === 278, `应用 SQL 语句数 (got ${appStmts})`);

// --- ws3：SyncedOpMetadata 元数据投影 CTE ---
const ws3 = app('ws3');
check(ws3.includes('MaxTitleOpId') && ws3.includes('ClientTitleData') && ws3.includes('ClientAgg'),
  'ws3 三段 CTE');
check(ws3.includes('opId >> 32'), 'ws3 opId 高位取时间戳');
check(ws3.includes('(ctd.titleOpTimestamp << 32) | COALESCE(som.editorSiteId, 0)'),
  'ws3 opId 打包 (ts<<32)|siteId');
check(ws3.includes('finalTitle') && ws3.includes('UNION ALL'),
  'ws3 finalTitle CASE 链 + UNION ALL 双分支');
check(ws3.includes('FROM SyncedOpMetadata som') && ws3.includes('FROM ClientOp'),
  'ws3 合并 SyncedOpMetadata + ClientOp');
check((ws3.match(/SELECT /g) || []).length === 17, 'ws3 共 17 处 SELECT');

// --- Harmony 等价实现 ---
const ident = readFileSync('note/src/main/ets/data/OperationIdentity.ets', 'utf8');
check(ident.includes('`op:${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}`'),
  'Harmony opId = op:hex-ts:hex-site');
check(/if \(left\.timestamp !== right\.timestamp\)[\s\S]*?left\.siteId < right\.siteId \? -1 : 1/.test(ident),
  'compareOperationIdentity = (timestamp,siteId) 字典序');

const title = readFileSync('note/src/main/ets/data/OriginalNoteTitlePersistence.ets', 'utf8');
check(title.includes('original_note_title_winner') && title.includes('materialized projection diverged'),
  'Harmony title winner 寄存器 + 发散自检');

const setMeta = readFileSync('note/src/main/ets/data/OriginalSetMetadataOperation.ets', 'utf8');
check(setMeta.includes('SET_METADATA_TITLE_IDENTITY_CONFLICT'), '标题身份冲突 defer');
check(setMeta.includes('compareOperationIdentity'), 'SET_METADATA 用同一决胜函数');

// --- 已知偏差登记：v7 迁移 op_id 字符串排序 ---
const helper = readFileSync('note/src/main/ets/data/DatabaseHelper.ets', 'utf8');
check(helper.includes('previous.op_id < current.op_id'), 'v7 迁移 op_id 字符串序（已登记偏差）');
check(helper.includes('DROP TABLE client_op'), 'client_op 表已随 v7 迁移废弃');

console.log(`${n}/${n} checks passed`);
