// Phase 847 — 1.0.3→1.4.2 类文件级增量
import { readdirSync } from 'node:fs';
import { join, relative } from 'node:path';

const A = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability';
const results = [];
const ck = (n, ok) => results.push([n, ok]);
const list = (root) => {
  const out = [];
  const walk = (d) => { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walk(p); else if (f.name.endsWith('.java')) out.push(relative(root, p).replace(/\\/g, '/')); } };
  walk(root);
  return out.sort();
};
const a = list(A), b = list(B);
const added = b.filter(f => !a.includes(f));
const removed = a.filter(f => !b.includes(f));

ck('1.0.3=122 / 1.4.2=162', a.length === 122 && b.length === 162);
ck('+42 新增', added.length === 42);
ck('−2 移除（均为 search 迁移）', removed.length === 2 && removed.every(f => f.startsWith('data/search/')));
ck('SearchResult 迁入 engine/appsearch', added.includes('data/search/engine/appsearch/SearchResult.java') && added.includes('data/search/engine/appsearch/C$$__AppSearch__SearchResult.java'));

// 新增域断言
const has = (s) => added.some(f => f.includes(s));
ck('calendar 簇', has('data/calendar/database/CalendarDatabase'));
ck('gallery outbox 簇', has('GalleryMutationDatabase') && has('GalleryMutationUploaderWorker') && has('GalleryPublishException'));
ck('hwr 远程进程簇', has('hwr/HwrEngineService') && has('hwr/PenSampleDecodingException') && has('hwr/RemoteEngineException'));
ck('loginstate×3', ['LibraryInitTimeoutException', 'LoginTeardownException', 'PostCommitLoginException'].every(n => has(`data/loginstate/${n}`)));
ck('user passkey/sso×4', ['MalformedPasskeyPayloadException', 'NullAuthTokenException', 'PasskeyActivityGoneException', 'SsoVerificationException'].every(n => has(`data/user/${n}`)));
ck('templates 簇', has('CustomTemplatesDatabase') && has('CustomTemplateSyncWorker'));
ck('sticker worker×2', has('StickerPackDownloadWorker') && has('StickerPackPrefetchWorker'));
ck('maintenance 链×4', has('BackgroundMaintenanceWorker') && has('ForegroundReturned'));
ck('基础设施三件套', has('ApiGatedFirebaseInitProvider') && has('DemoResetWorker') && has('UnresolvableWorker'));
ck('snapshot 异常×2', has('snapshot/SnapshotFormatException') && has('snapshot/SnapshotUnsupportedException'));
ck('NoteOpsGone 新增', has('ops/synced/NoteOpsGoneException'));
ck('NoteLimitRefused 新增', has('notelimit/NoteLimitRefusedException'));
ck('PreemptedByOpenNote 新增', has('PreemptedByOpenNoteException'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
