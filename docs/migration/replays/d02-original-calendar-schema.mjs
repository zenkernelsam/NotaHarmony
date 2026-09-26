// D02 原版 1.4.2 日历/大纲 Room schema — Phase 765（ADR-0708 版本差待审细化）
// 钉住 CalendarDatabase 四表 DDL、共享 INSERT 适配器、级联删除与 180 天裁剪语义。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const dbImpl = `${base}/com/gingerlabs/notability/data/calendar/database/CalendarDatabase_Impl.java`;
const yf1 = `${base}/defpackage/yf1.java`;
const wf1 = `${base}/defpackage/wf1.java`;
const yg1 = `${base}/defpackage/yg1.java`;
const lr = `${base}/defpackage/lr.java`;
const sx0 = `${base}/defpackage/sx0.java`;
const rgh = `${base}/defpackage/rgh.java`;
const wg1 = `${base}/defpackage/wg1.java`;
const ohh = `${base}/defpackage/ohh.java`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('CalendarDatabase_Impl exists (1.4.2-only surface)', fs.existsSync(dbImpl));
const impl = fs.readFileSync(dbImpl, 'utf8');
check('invalidation tracker declares exactly 4 calendar tables',
  impl.includes('"calendarSelections", "calendarDismissedEvents", "syllabusCourses", "syllabusEvents"'));

const yf1s = fs.readFileSync(yf1, 'utf8');
check('calendarSelections DDL: single calendarId PK',
  yf1s.includes('CREATE TABLE IF NOT EXISTS `calendarSelections` (`calendarId` TEXT NOT NULL, PRIMARY KEY(`calendarId`))'));
check('calendarDismissedEvents DDL: eventId PK + dismissedAtMillis',
  yf1s.includes('CREATE TABLE IF NOT EXISTS `calendarDismissedEvents` (`eventId` TEXT NOT NULL, `dismissedAtMillis` INTEGER NOT NULL, PRIMARY KEY(`eventId`))'));
check('syllabusCourses DDL: folderId PK + nullable meetingTimeLine',
  yf1s.includes('CREATE TABLE IF NOT EXISTS `syllabusCourses` (`folderId` TEXT NOT NULL, `courseName` TEXT NOT NULL, `meetingTimeLine` TEXT, `importedAtMillis` INTEGER NOT NULL, PRIMARY KEY(`folderId`))'));
check('syllabusEvents DDL + folderId index',
  yf1s.includes('`syllabusEvents` (`id` TEXT NOT NULL, `folderId` TEXT NOT NULL, `title` TEXT NOT NULL, `startMillis` INTEGER NOT NULL, `endMillis` INTEGER NOT NULL, `isAllDay` INTEGER NOT NULL, `type` TEXT NOT NULL, PRIMARY KEY(`id`))')
  && yf1s.includes('CREATE INDEX IF NOT EXISTS `index_syllabusEvents_folderId` ON `syllabusEvents` (`folderId`)'));
check('wf1 validation delegate carries the same syllabus DDL',
  fs.readFileSync(wf1, 'utf8').includes('syllabusCourses` (`folderId` TEXT NOT NULL'));

const yg1s = fs.readFileSync(yg1, 'utf8');
check('selection insert is OR REPLACE single-column',
  yg1s.includes('INSERT OR REPLACE INTO `calendarSelections` (`calendarId`) VALUES (?)'));
check('syllabus inserts are OR ABORT (courses 4 cols, events 7 cols)',
  yg1s.includes('INSERT OR ABORT INTO `syllabusCourses` (`folderId`,`courseName`,`meetingTimeLine`,`importedAtMillis`) VALUES (?,?,?,?)')
  && yg1s.includes('INSERT OR ABORT INTO `syllabusEvents` (`id`,`folderId`,`title`,`startMillis`,`endMillis`,`isAllDay`,`type`) VALUES (?,?,?,?,?,?,?)'));

const lrs = fs.readFileSync(lr, 'utf8');
check('dismissed tombstones pruned by dismissedAtMillis cutoff',
  lrs.includes('DELETE FROM calendarDismissedEvents WHERE dismissedAtMillis < ?'));
check('syllabus events pruned by endMillis cutoff + stale course probe by importedAtMillis',
  lrs.includes('DELETE FROM syllabusEvents WHERE endMillis < ?')
  && lrs.includes('SELECT folderId FROM syllabusCourses WHERE importedAtMillis < ?'));

const sx0s = fs.readFileSync(sx0, 'utf8');
check('selection replaceAll = full DELETE + reinsert + id flow',
  sx0s.includes('DELETE FROM calendarSelections') && sx0s.includes('SELECT calendarId FROM calendarSelections'));

const rghs = fs.readFileSync(rgh, 'utf8');
check('syllabus folder-scoped cascade delete by folderId IN',
  rghs.includes('DELETE FROM syllabusCourses WHERE folderId IN (')
  && rghs.includes('DELETE FROM syllabusEvents WHERE folderId IN ('));

check('calendar repository keeps a 180-day dismissal retention window',
  fs.readFileSync(wg1, 'utf8').includes('Duration.ofDays(180L)'));
check('syllabus repository pairs 180-day retention with a 1-minute import freshness probe',
  fs.readFileSync(ohh, 'utf8').includes('Duration.ofDays(180L)')
  && fs.readFileSync(ohh, 'utf8').includes('Duration.ofMinutes(1L)'));

console.log(`calendar schema replay: ${checks.length}/${checks.length} checks green`);
