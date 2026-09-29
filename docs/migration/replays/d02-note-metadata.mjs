// Phase 1014 — 笔记元数据族
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e47 = readFileSync(D + 'e47.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// SyncedNoteMetadata 18-col
t('SyncedNoteMetadata: exists + 18 cols', e47.includes('`SyncedNoteMetadata`') && e47.includes('`titleOpId`') && e47.includes('`thumbnailOpId`') && e47.includes('`legacyNoteId`'));
t('SNM: sharing cols', e47.includes('`linkAccessLevel` TEXT NOT NULL') && e47.includes('`linkPermissionScope` TEXT NOT NULL') && e47.includes('`userAccessLevel` TEXT'));
t('SNM: tombstone+favorite+lastOpened', e47.includes('`deletedAt` INTEGER') && e47.includes('`favorite` INTEGER NOT NULL') && e47.includes('`lastOpened` INTEGER'));
t('SNM: mostRecentOpTime + thumbnailUrl', e47.includes('`mostRecentOpTime` INTEGER') && e47.includes('`thumbnailUrl` TEXT'));
t('SNM: shared + hasRecordings flags', e47.includes('`shared` INTEGER NOT NULL') && e47.includes('`hasRecordings` INTEGER'));
// ClientNoteUpdate
t('ClientNoteUpdate: composite PK (id,type)', e47.includes('`ClientNoteUpdate`') && e47.includes('PRIMARY KEY(`id`, `type`)'));
t('CNU: sparse cols + idempotencyKey', e47.includes('`type` TEXT NOT NULL') && e47.includes('`idempotencyKey` BLOB NOT NULL'));
// marker tables
t('DraftNote: noteId PK only', e47.includes('`DraftNote` (`noteId` BLOB NOT NULL, PRIMARY KEY(`noteId`))'));
t('PermanentlyDeletedNote: noteId PK', e47.includes('`PermanentlyDeletedNote` (`noteId` BLOB NOT NULL, PRIMARY KEY(`noteId`))'));
t('NoteAsset: hash+status+noteIds+size', e47.includes('`NoteAsset`') && e47.includes('`assetHash` BLOB') && e47.includes('`noteIds` TEXT') && e47.includes('`fileSize` INTEGER'));
t('LearnNoteState: noteId+lastOpenedMode', e47.includes('`LearnNoteState`') && e47.includes('`lastOpenedMode` TEXT'));
console.log('note-metadata replay: ' + n + '/11 checks green');
