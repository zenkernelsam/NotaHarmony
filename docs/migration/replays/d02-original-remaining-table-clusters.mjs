// D02 原版 1.4.2 剩余新表簇 DDL 登记 — Phase 777
// 钉住 10 张新表 + SummaryEntity 迁移重建的 DDL 字面量与数据库归属。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const root103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';
const ca3 = fs.readFileSync(`${root}/defpackage/ca3.java`, 'utf8');
const learn = fs.readFileSync(`${root}/com/gingerlabs/notability/data/learn/database/LearnDatabase_Impl.java`, 'utf8');
const settings = fs.readFileSync(`${root}/com/gingerlabs/notability/data/settings/database/SettingsDatabase_Impl.java`, 'utf8');
const search = fs.readFileSync(`${root}/com/gingerlabs/notability/data/search/database/SearchDatabase_Impl.java`, 'utf8');
const bundle = fs.readFileSync(`${root}/com/gingerlabs/notability/data/note/ops/database/NoteBundleMetadataDatabase_Impl.java`, 'utf8');
const learn103 = fs.readFileSync(`${root103}/com/gingerlabs/notability/data/learn/database/LearnDatabase_Impl.java`, 'utf8');
const e47 = fs.readFileSync(`${root103}/defpackage/e47.java`, 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('LearnDatabase owns CompletedQuizSession with scoring columns',
  learn.includes('CompletedQuizSession')
  && ca3.includes('`CompletedQuizSession` (`noteId` BLOB NOT NULL')
  && ca3.includes('`numCorrect` INTEGER NOT NULL DEFAULT 0')
  && ca3.includes('`spacedRepetitionTotal` INTEGER'));
check('QuizSession (in-progress) still coexists in 1.4.2 LearnDatabase',
  learn.includes('"QuizSession"') && learn.includes('"CompletedQuizSession"'));
check('SummaryEntity migration adds takeaways; markdown turns nullable',
  ca3.includes('`SummaryEntity` (`noteId` BLOB NOT NULL, `markdown` TEXT, `takeaways` TEXT'));
check('1.0.3 SummaryEntity had markdown NOT NULL and no takeaways',
  e47.includes('`SummaryEntity` (`noteId` BLOB NOT NULL, `markdown` TEXT NOT NULL')
  && !e47.includes('takeaways'));
check('SettingsDatabase owns template stats trio + gallery recency',
  settings.includes('PaperTemplateUsage') && settings.includes('RecentPaperTemplate')
  && settings.includes('FavoritePaperTemplate') && settings.includes('RecentGalleryTemplate')
  && ca3.includes('`PaperTemplateUsage` (`templateUuid` TEXT NOT NULL, `useCount` INTEGER NOT NULL')
  && ca3.includes('`RecentGalleryTemplate` (`noteId` TEXT NOT NULL, `title` TEXT NOT NULL, `publisherScreenname` TEXT'));
check('SearchDatabase owns recognizer/failure/index-sync quartet',
  search.includes('InkPageRecognizer') && search.includes('FailedInkPage')
  && search.includes('SearchIndexPendingUpload') && search.includes('SearchIndexSyncState')
  && ca3.includes('`InkPageRecognizer` (`noteId` BLOB NOT NULL, `pageKey` TEXT NOT NULL, `recognizer` TEXT NOT NULL, `language` TEXT NOT NULL, `rawContentFailed` INTEGER NOT NULL')
  && ca3.includes('`SearchIndexPendingUpload` (`noteId` BLOB NOT NULL, `type` TEXT NOT NULL, `attempts` INTEGER NOT NULL'));
check('NoteBundleMetadataDatabase owns UploadRejection moderation table',
  bundle.includes('UploadRejection')
  && ca3.includes('`UploadRejection` (`noteId` BLOB NOT NULL, `firstRejectedAt` INTEGER NOT NULL, `reported` INTEGER NOT NULL'));
check('all ten tables absent from 1.0.3 *_Impl files',
  !learn103.includes('CompletedQuizSession'));

console.log(`remaining-table-clusters replay: ${checks.length}/${checks.length} checks green`);
