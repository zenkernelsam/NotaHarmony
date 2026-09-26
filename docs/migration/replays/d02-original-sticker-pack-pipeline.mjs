// D02 原版 1.4.2 贴纸包安装/下载管道 — Phase 770（Phase 763 split 的运行时侧）
// 钉住 split-first/CDN-fallback 解析、bwg 校验器、hwg 状态登记与双 Worker。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const packs = `${base}/com/gingerlabs/notability/feature/note/stickers/packs`;
const pq3 = `${base}/defpackage/pq3.java`;
const hwg = `${base}/defpackage/hwg.java`;
const mo1 = `${base}/defpackage/mo1.java`;
const bwg = `${base}/defpackage/bwg.java`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const pq3s = fs.readFileSync(pq3, 'utf8');
check('installer resolves stickers split directory first',
  pq3s.includes('b("stickers")') && pq3s.includes('implements iwg'));
check('split hit validated by bwg before remote fallback',
  pq3s.includes('bwg.a(file2)') && pq3s.includes('this.b.a(cwgVar)'));

const mo1s = fs.readFileSync(mo1, 'utf8');
check('remote downloader is CDN-keyed with pack/delivery/version params',
  mo1s.includes('"cdn"') && mo1s.includes('"sticker.pack"')
  && mo1s.includes('"sticker.pack.delivery"') && mo1s.includes('"sticker.pack.version"'));

const bwgs = fs.readFileSync(bwg, 'utf8');
check('pack validator accepts webp/png/jpg/jpeg directories',
  bwgs.includes('"webp"') && bwgs.includes('"png"') && bwgs.includes('"jpg"'));

const hwgs = fs.readFileSync(hwg, 'utf8');
check('download registry holds installed-set StateFlow + event Channel',
  hwgs.includes('new a8g') || hwgs.includes('b8g.b(0, 8'));

const dl = fs.readFileSync(`${packs}/StickerPackDownloadWorker.java`, 'utf8');
const pf = fs.readFileSync(`${packs}/StickerPackPrefetchWorker.java`, 'utf8');
check('both workers are CoroutineWorkers sharing iwg+hwg deps',
  dl.includes('extends CoroutineWorker') && dl.includes('Liwg;') && dl.includes('Lhwg;')
  && pf.includes('extends CoroutineWorker') && pf.includes('Liwg;') && pf.includes('Lhwg;'));

console.log(`sticker pack pipeline replay: ${checks.length}/${checks.length} checks green`);
