// D02 原版 1.4.2 模板同步管道 — Phase 769（Phase 764 schema 同步侧补全）
// 钉住双 Worker、s93 编排器结构、墓碑排空与 pendingSync 页同步线。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const syncWorker = `${base}/com/gingerlabs/notability/data/templates/sync/CustomTemplateSyncWorker.java`;
const pageWorker = `${base}/com/gingerlabs/notability/data/settings/sync/TemplatePageSyncWorker.java`;
const s93 = `${base}/defpackage/s93.java`;
const kuc = `${base}/defpackage/kuc.java`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const sw = fs.readFileSync(syncWorker, 'utf8');
check('CustomTemplateSyncWorker is a CoroutineWorker injecting s93 orchestrator',
  sw.includes('extends CoroutineWorker') && sw.includes('Ls93;'));

const s93s = fs.readFileSync(s93, 'utf8');
check('orchestrator carries sync-scoped uncaught-exception channel',
  s93s.includes('"Uncaught custom template sync exception"'));
check('orchestrator tracks progress with AtomicInteger + dual mutexes',
  s93s.includes('new AtomicInteger()') && s93s.includes('new oha()'));
check('orchestrator emits CustomTemplateSync analytics tag',
  s93s.includes('"CustomTemplateSync"'));

const kucs = fs.readFileSync(kuc, 'utf8');
check('tombstone queue drained by assetId batch delete',
  kucs.includes('DELETE FROM PendingTemplateDeletion WHERE assetId IN ('));

const pw = fs.readFileSync(pageWorker, 'utf8');
check('TemplatePageSyncWorker is a separate page-level CoroutineWorker',
  pw.includes('extends CoroutineWorker') && pw.includes('Lbth;'));

console.log(`template sync replay: ${checks.length}/${checks.length} checks green`);
