// D02 原版 1.4.2 反编译登记与版本差异初筛 — Phase 760（ADR-0708）
// 钉住：decompiled_1.4.2 证据树存在性、APK/XAPK 指纹、1.4.2 新功能簇标志类、
// manifest 新组件/权限、字符串新增族。非混淆签名面有效；defpackage 混淆名不 diff。
import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';

const nroot = 'C:/Users/Cisco He/Desktop/Notability';
const d142 = `${nroot}/decompiled_1.4.2`;
const d103 = `${nroot}/decompiled_1.0.3`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('decompiled_1.4.2 evidence tree exists with sources+resources',
  fs.existsSync(`${d142}/sources`) && fs.existsSync(`${d142}/resources`));

const apk = `${nroot}/Notability_1.4.2/com.gingerlabs.notability.apk`;
const sha = crypto.createHash('sha256').update(fs.readFileSync(apk)).digest('hex');
check('base APK SHA-256 fingerprint matches registered extraction',
  sha === '764af402881befd7fa1c52d3688b2a1e91f4decaa41ddd42af0c313fbfe9f992');

const manifest = fs.readFileSync(`${d142}/resources/AndroidManifest.xml`, 'utf8');
check('1.4.2 manifest carries versionCode 1040002 / versionName 1.4.2',
  manifest.includes('1040002') && manifest.includes('1.4.2'));
check('1.4.2 declares remote HWR engine service + calendar permission',
  manifest.includes('com.gingerlabs.notability.data.handwritingrecognition.hwr.HwrEngineService') &&
  manifest.includes('android.permission.READ_CALENDAR'));

const g = cls => fs.existsSync(`${d142}/sources/com/gingerlabs/notability/${cls}`);
check('1.4.2 gallery outbox cluster exists',
  g('data/gallery/outbox/GalleryMutationDatabase.java') &&
  g('data/gallery/outbox/GalleryMutationUploaderWorker.java') &&
  g('data/gallery/GalleryPublishException.java'));
check('1.4.2 calendar cluster exists',
  g('data/calendar/database/CalendarDatabase.java'));
check('1.4.2 custom-template sync cluster exists',
  g('data/templates/database/CustomTemplatesDatabase.java') &&
  g('data/templates/sync/CustomTemplateSyncWorker.java'));
check('1.4.2 remote handwriting-recognition cluster exists',
  g('data/handwritingrecognition/hwr/HwrEngineService.java') &&
  g('data/handwritingrecognition/hwr/RemoteEngineException.java') &&
  g('data/handwritingrecognition/myscript/MyScriptEngineFeedException.java'));
check('1.4.2 passkey/SSO cluster exists',
  g('data/user/MalformedPasskeyPayloadException.java') &&
  g('data/user/SsoVerificationException.java'));
check('1.4.2 sticker-pack download cluster exists',
  g('feature/note/stickers/packs/StickerPackDownloadWorker.java') &&
  g('feature/note/stickers/packs/StickerPackPrefetchWorker.java'));
check('1.4.2 note-limit + syllabus + snapshot sentinels exist',
  g('data/library/state/notelimit/NoteLimitRefusedException.java') &&
  g('data/learn/syllabus/SyllabusParseException.java') &&
  g('core/model/snapshot/SnapshotFormatException.java'));
check('1.4.2 zstd-jni vendor library present',
  fs.existsSync(`${d142}/sources/com/github/luben/zstd/Zstd.java`));

const s142 = fs.readFileSync(`${d142}/resources/res/values/strings.xml`, 'utf8');
const s103 = fs.readFileSync(`${d103}/resources/res/values/strings.xml`, 'utf8');
check('1.4.2 adds gallery social surface strings',
  s142.includes('feature_library_gallery__publish') === false &&
  s142.includes('feature_library_gallery__comments') &&
  s142.includes('ui_share__gallery_publish') &&
  !s103.includes('feature_library_gallery__comments'));
check('1.4.2 adds sticker store + template hub + learn syllabus strings',
  s142.includes('feature_note_stickers__download_pack') &&
  s142.includes('ui_templates__save_as_template') &&
  s142.includes('ui_learn__syllabus_parsing_header') &&
  !s103.includes('feature_note_stickers__download_pack'));
check('1.4.2 adds passkey + calendar-connect strings',
  s142.includes('feature_login__sign_in_with_passkey') &&
  s142.includes('feature_settings__connect_calendar'));

const adr = fs.readFileSync('docs/migration/adr/ADR-0708-original-1.4.2-version-delta-scope.md', 'utf8');
const ev = fs.readFileSync('docs/migration/evidence/original-1.4.2-decompile-version-delta.md', 'utf8');
check('ADR-0708 registers version-delta disposition',
  adr.includes('版本基线不变') && adr.includes('fail-closed') && adr.includes('T-042'));
check('evidence doc carries both fingerprints and delta families',
  ev.includes('d754ab3b2796ec4232996819f102d7adbbfe2ec9cdbd286cdd43d2993a20ff70') &&
  ev.includes('764af402881befd7fa1c52d3688b2a1e91f4decaa41ddd42af0c313fbfe9f992') &&
  ev.includes('feature_library_gallery__'));

console.log(`D02_ORIGINAL_1_4_2_VERSION_DELTA_OK TOTAL=${checks.length} FAILED=0`);
