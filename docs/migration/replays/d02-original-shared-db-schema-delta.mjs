// D02 原版 1.4.2 共享数据库表/列增量 — Phase 767（ADR-0708 版本差细化）
// 钉住 9 个新表簇 DDL 与既有表 ALTER 增量（工具状态/测验评分/纯文本态）。
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = 'C:/Users/Cisco He/Desktop/Notability';
const src142 = path.join(root, 'decompiled_1.4.2/sources');
const src103 = path.join(root, 'decompiled_1.0.3/sources');

const collect = (dir) => {
  const out = new Set();
  const walk = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.java')) {
        const s = fs.readFileSync(p, 'utf8');
        for (const m of s.matchAll(/CREATE TABLE IF NOT EXISTS `([A-Za-z_]+)`/g)) out.add(m[1]);
      }
    }
  };
  walk(dir);
  return out;
};

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const t142 = collect(src142);
const t103 = collect(src103);

check('1.4.2 has strictly more tables than 1.0.3', t142.size > t103.size);
const newTables = [...t142].filter((t) => !t103.has(t));
const removed = [...t103].filter((t) => !t142.has(t));
check('no 1.0.3 table was removed in 1.4.2', removed.length === 0);

const expectedNew = [
  'calendarSelections', 'calendarDismissedEvents', 'syllabusCourses', 'syllabusEvents',
  'PendingLike', 'PendingFollow', 'CustomTemplate', 'PendingTemplateDeletion',
  'CompletedQuizSession', 'FailedInkPage', 'InkPageRecognizer',
  'FavoritePaperTemplate', 'RecentPaperTemplate', 'PaperTemplateUsage', 'TemplatePaperInfo',
  'RecentGalleryTemplate', 'SearchIndexPendingUpload', 'SearchIndexSyncState',
  'UploadRejection', 'ToolStateEntity_new', '_new_SummaryEntity',
];
check('all 21 registered new tables appear in the 1.4.2 diff', expectedNew.every((t) => newTables.includes(t)));

const readAll = (dir) => {
  let s = '';
  const walk = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.java')) s += fs.readFileSync(p, 'utf8');
    }
  };
  walk(dir);
  return s;
};
const all142 = readAll(src142);

check('ToolStateEntity gained googleInkBrushPackId + shapeKind + penLastStandardColorWellIndex',
  all142.includes('ALTER TABLE `ToolStateEntity` ADD COLUMN `googleInkBrushPackId` INTEGER DEFAULT NULL')
  && all142.includes("ALTER TABLE `ToolStateEntity` ADD COLUMN `shapeKind` TEXT DEFAULT 'RECTANGLE'")
  && all142.includes('ALTER TABLE `ToolStateEntity` ADD COLUMN `penLastStandardColorWellIndex` INTEGER DEFAULT NULL'));
check('NoteStateEntity gained isTextOnly flag',
  all142.includes('ALTER TABLE `NoteStateEntity` ADD COLUMN `isTextOnly` INTEGER DEFAULT NULL'));
check('QuizSession gained scoring + spacedRepetitionTotal columns',
  all142.includes('ALTER TABLE `QuizSession` ADD COLUMN `numCorrect` INTEGER NOT NULL DEFAULT 0')
  && all142.includes('ALTER TABLE `QuizSession` ADD COLUMN `spacedRepetitionTotal` INTEGER DEFAULT NULL'));
check('FailedInkPage/InkPageRecognizer carry noteId+pageKey composite PKs',
  all142.includes('`FailedInkPage` (`noteId` BLOB NOT NULL, `pageKey` TEXT NOT NULL, PRIMARY KEY(`noteId`, `pageKey`)')
  && all142.includes('`InkPageRecognizer` (`noteId` BLOB NOT NULL, `pageKey` TEXT NOT NULL, `recognizer` TEXT NOT NULL, `language` TEXT NOT NULL'));
check('SummaryEntity rebuild-migration adds takeaways column',
  all142.includes('`SummaryEntity` (`noteId` BLOB NOT NULL, `markdown` TEXT, `takeaways` TEXT, PRIMARY KEY(`noteId`)'));
check('search-index sync tables pair pending-upload queue with sync-state',
  all142.includes('`SearchIndexPendingUpload` (`noteId` BLOB NOT NULL, `type` TEXT NOT NULL, `attempts` INTEGER NOT NULL')
  && all142.includes('`SearchIndexSyncState` (`noteId` BLOB NOT NULL, `type` TEXT NOT NULL, `lastSyncedServerTime` INTEGER NOT NULL'));

console.log(`shared-db schema delta replay: ${checks.length}/${checks.length} checks green`);
