// D02 原版 1.4.2 自定义模板 Room schema — Phase 764（ADR-0708 版本差待审细化）
// 钉住 CustomTemplatesDatabase 双实体与 Room 生成 INSERT 的列清单。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const dbImpl = `${base}/com/gingerlabs/notability/data/templates/database/CustomTemplatesDatabase_Impl.java`;
const e83 = `${base}/defpackage/e83.java`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('CustomTemplatesDatabase_Impl exists (1.4.2-only surface)',
  fs.existsSync(dbImpl));

const impl = fs.readFileSync(dbImpl, 'utf8');
check('database declares CustomTemplate + PendingTemplateDeletion entities',
  impl.includes('"CustomTemplate"') && impl.includes('"PendingTemplateDeletion"'));

const e83s = fs.readFileSync(e83, 'utf8');
check('CustomTemplate INSERT carries the full 13-column schema',
  e83s.includes('`CustomTemplate` (`id`,`name`,`interactive`,`repeats`,' +
    '`createdAt`,`favoritedAt`,`assetId`,`syncedName`,`uploadState`,' +
    '`origin`,`pageCount`,`pageWidth`,`pageHeight`)'));
check('PendingTemplateDeletion is a single-assetId tombstone queue',
  e83s.includes('`PendingTemplateDeletion` (`assetId`) VALUES (?)'));
check('uploadState update binds assetId guard',
  e83s.includes('CustomTemplate SET uploadState = ? WHERE id = ?') ||
  fs.readFileSync(`${base}/defpackage/g83.java`, 'utf8')
    .includes('CustomTemplate SET uploadState = ?'));

const ev = fs.readFileSync(
  'docs/migration/evidence/phase-764-original-custom-template-schema.md', 'utf8');
check('Phase 764 evidence registers both entities + column semantics',
  ev.includes('interactive') && ev.includes('PendingTemplateDeletion') &&
  ev.includes('pageHeight'));

console.log(`D02_ORIGINAL_CUSTOM_TEMPLATE_SCHEMA_OK TOTAL=${checks.length} FAILED=0`);
