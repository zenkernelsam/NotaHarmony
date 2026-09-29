// Phase 992 — e47 full Room DDL: 33 app tables + key PK/FK details
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const e47 = readFileSync(`${ROOT}/e47.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// All 33 app tables present in DDL (WorkManager 6 excluded by name check below)
const appTables = ['QuizSession','QuizOp','LearnNoteState','SummaryEntity','LearnJob','StudyItemsInfo','NoteAsset','SyncedOpMetadata','ClientOp','NoteIndexableChanges','DeferredSyncedOps','DraftNote','NoteStateEntity','SyncedNoteMetadata','ClientNoteUpdate','PermanentlyDeletedNote','SyncedFolderMetadata','ClientFolderEdit','ClientFolderDelete','IndexedTitle','IndexedNote','FailedIndexedNote','search_item','PaperBackground','BackgroundInfo','TrayEntity','FavoriteColorWellEntity','WidthSizeWellEntity','ToolStateEntity','ToolboxEntity','RecentColorWellEntity','transcriptions','transcription_segments','Preference'];
for (const t of appTables)
  ok(e47.includes('`' + t + '` ('), `DDL: ${t}`);

// Key PK/FK/type details
ok(/`ClientOp` \(`noteId` BLOB NOT NULL, `op` BLOB NOT NULL[\s\S]*PRIMARY KEY\(`noteId`, `opId`\)/.test(e47), 'ClientOp: composite PK (noteId,opId)');
ok(/`DeferredSyncedOps`[\s\S]{0,200}`tableType` TEXT NOT NULL, `fileSize` INTEGER NOT NULL, `checksum` INTEGER NOT NULL/.test(e47), 'DeferredSyncedOps: tableType+fileSize+checksum');
ok(/`NoteIndexableChanges`[\s\S]{0,260}PRIMARY KEY\(`noteId`, `processing`, `chunkIndex`\)/.test(e47), 'NoteIndexableChanges: 3-part PK');
ok(/`ClientFolderEdit`[\s\S]{0,240}`uploaded` INTEGER NOT NULL DEFAULT false/.test(e47), 'ClientFolderEdit: uploaded DEFAULT false');
ok(/`ToolStateEntity`[\s\S]{0,340}`tapePattern` INTEGER DEFAULT NULL/.test(e47), 'ToolStateEntity: tapePattern column');
ok(/`ToolStateEntity`[\s\S]{0,400}FOREIGN KEY\(`tray_owner_id`\) REFERENCES `TrayEntity`\(`tray_id`\)[\s\S]{0,40}ON DELETE CASCADE/.test(e47), 'ToolStateEntity->Tray CASCADE FK');
ok(/`transcription_segments`[\s\S]{0,240}FOREIGN KEY\(`transcriptionId`\)[\s\S]{0,60}ON DELETE CASCADE/.test(e47), 'segments->transcriptions CASCADE FK');
ok(/`transcriptions`[\s\S]{0,160}`sha512Hash` TEXT NOT NULL/.test(e47), 'transcriptions: sha512Hash');
ok(/`search_item`[\s\S]{0,200}`rects` BLOB/.test(e47), 'search_item: rects BLOB');
ok(/`SyncedNoteMetadata`[\s\S]{0,500}`linkAccessLevel` TEXT NOT NULL, `linkPermissionScope` TEXT NOT NULL/.test(e47), 'SyncedNoteMetadata: link share cols');
ok(/`Preference` \(`key` TEXT NOT NULL, `long_value` INTEGER, PRIMARY KEY\(`key`\)\)/.test(e47), 'Preference: key->long_value KV');

console.log(`\nfull-room-ddl replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
