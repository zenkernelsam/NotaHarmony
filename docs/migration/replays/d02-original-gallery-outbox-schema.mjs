// D02 原版 1.4.2 画廊互动 Outbox Room schema — Phase 766（ADR-0708 画廊后端簇细化）
// 钉住 GalleryMutationDatabase 双表 DDL、upsert 适配器与排空/清理语句。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const dbImpl = `${base}/com/gingerlabs/notability/data/gallery/outbox/GalleryMutationDatabase_Impl.java`;
const worker = `${base}/com/gingerlabs/notability/data/gallery/outbox/GalleryMutationUploaderWorker.java`;
const ca3 = `${base}/defpackage/ca3.java`;
const yg1 = `${base}/defpackage/yg1.java`;
const pd2 = `${base}/defpackage/pd2.java`;
const vtc = `${base}/defpackage/vtc.java`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('GalleryMutationDatabase_Impl exists (1.4.2-only surface)', fs.existsSync(dbImpl));
const impl = fs.readFileSync(dbImpl, 'utf8');
check('invalidation tracker declares PendingLike + PendingFollow',
  impl.includes('"PendingLike", "PendingFollow"'));

const ca3s = fs.readFileSync(ca3, 'utf8');
check('PendingLike DDL: noteId PK + liked INTEGER',
  ca3s.includes('CREATE TABLE IF NOT EXISTS `PendingLike` (`noteId` TEXT NOT NULL, `liked` INTEGER NOT NULL, PRIMARY KEY(`noteId`))'));
check('PendingFollow DDL: userId PK + following INTEGER',
  ca3s.includes('CREATE TABLE IF NOT EXISTS `PendingFollow` (`userId` TEXT NOT NULL, `following` INTEGER NOT NULL, PRIMARY KEY(`userId`))'));

const yg1s = fs.readFileSync(yg1, 'utf8');
check('PendingLike INSERT binds noteId+liked',
  yg1s.includes('INSERT INTO `PendingLike` (`noteId`,`liked`) VALUES (?,?)'));
check('PendingFollow INSERT binds userId+following',
  yg1s.includes('INSERT INTO `PendingFollow` (`userId`,`following`) VALUES (?,?)'));

const pd2s = fs.readFileSync(pd2, 'utf8');
check('PendingLike upsert UPDATE on noteId PK',
  pd2s.includes('UPDATE `PendingLike` SET `noteId` = ?,`liked` = ? WHERE `noteId` = ?'));
check('PendingFollow upsert UPDATE on userId PK',
  pd2s.includes('UPDATE `PendingFollow` SET `userId` = ?,`following` = ? WHERE `userId` = ?'));

const vtcs = fs.readFileSync(vtc, 'utf8');
check('PendingLike DAO uses yg1(4)+pd2(3) upsert adapter',
  vtcs.includes('op4(new yg1(4), new pd2(3))'));

check('uploader is a CoroutineWorker (WorkManager drain to backend)',
  fs.existsSync(worker)
  && fs.readFileSync(worker, 'utf8').includes('extends CoroutineWorker'));

console.log(`gallery outbox schema replay: ${checks.length}/${checks.length} checks green`);
