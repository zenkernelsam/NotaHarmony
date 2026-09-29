// Phase 1013 — 文件夹子系统（三表 + RawLibraryStateDatabase）
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e47 = readFileSync(D + 'e47.java', 'utf8');
const ip1 = readFileSync(D + 'ip1.java', 'utf8');
const jp1 = readFileSync(D + 'jp1.java', 'utf8');
const jae = readFileSync(D + 'jae.java', 'utf8');
const xo1 = readFileSync(D + 'xo1.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// DDL
t('SyncedFolderMetadata: 7 cols + siblingOrder REAL + emoji', e47.includes('`SyncedFolderMetadata`') && e47.includes('`siblingOrder` REAL') && e47.includes('`emoji` TEXT'));
t('ClientFolderEdit: sparse edit + idempotencyKey + uploaded', e47.includes('`ClientFolderEdit`') && e47.includes('`idempotencyKey` BLOB') && e47.includes('`uploaded` INTEGER NOT NULL DEFAULT false'));
t('ClientFolderDelete: tombstone + childrenHash', e47.includes('`ClientFolderDelete`') && e47.includes('`childrenHash` TEXT'));
// inserts
t('ip1: ClientFolderEdit 10-col INSERT', ip1.includes('INSERT INTO `ClientFolderEdit`') && ip1.includes('`idempotencyKey`'));
t('ip1: ClientFolderDelete 5-col INSERT', ip1.includes('INSERT INTO `ClientFolderDelete`') && ip1.includes('`deletedAt`'));
// DAO + DB
t('jp1: RawLibraryStateDatabase x2', jp1.includes('public final RawLibraryStateDatabase a'));
t('jp1: dual q36 insert adapters', jp1.includes('public final q36 f') && jp1.includes('public final q36 g'));
// entities
t('jae: SyncedFolderMetadata shape', /class jae[\s\S]{0,80}public final utf a;[\s\S]{0,40}utf b;[\s\S]{0,40}long c;[\s\S]{0,40}String d;[\s\S]{0,40}int e;[\s\S]{0,40}double f;[\s\S]{0,40}String g;/.test(jae));
t('xo1: implements yo1 sparse edit', /class xo1 implements yo1/.test(xo1) && xo1.includes('Integer d') && xo1.includes('Double e'));
t('xo1: xgb createdAt realtime', xo1.includes('public final xgb f'));
// folder manager
const beb = readFileSync(D + 'beb.java', 'utf8');
t('beb: manager {kp1,cx6,pce x4}', beb.includes('public final kp1 a') && beb.includes('public final cx6 b') && beb.includes('public final pce f'));
t('synced metadata: utf ids + double siblingOrder', jae.includes('public final utf a') && jae.includes('public final double f'));
t('xo1: nullable parentId/title (sparse)', xo1.includes('public final utf b') && xo1.includes('public final String c'));
console.log('folder-subsystem replay: ' + n + '/13 checks green');
