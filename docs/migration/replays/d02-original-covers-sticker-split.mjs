// D02 原版 1.4.2 封面资产 + stickers.apk split — Phase 763（ADR-0708 版本差）
// 钉住 covers/ 十件 PDF 与 stickers.apk 的 39 包 webp 结构。
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const nroot = 'C:/Users/Cisco He/Desktop/Notability';
const coversDir = `${nroot}/decompiled_1.4.2/resources/assets/covers`;
const xapk = `${nroot}/Notability_1.4.2/Notability%3A+AI+Note+Workspace_1.4.2_apkcombo.com.xapk`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('covers/ exists with exactly ten PDF-1.7 files', (() => {
  const fs_ = fs.readdirSync(coversDir).filter(f => f.endsWith('.pdf'));
  return fs_.length === 10 &&
    fs_.every(f => fs.readFileSync(path.join(coversDir, f)).subarray(0, 8)
      .toString('latin1').startsWith('%PDF-1.7'));
})());

check('covers include the preset-sticker sheet referenced by ui_notecovers',
  fs.existsSync(path.join(coversDir, 'stickers.pdf')));

// xapk central directory → stickers.apk presence + size
const buf = fs.readFileSync(xapk);
check('xapk carries stickers.apk as an independent split member',
  buf.includes(Buffer.from('stickers.apk')) &&
  buf.includes(Buffer.from('config.arm64_v8a.apk')));

// read stickers.apk via stored-member extraction (data-descriptor layout)
const eocd = buf.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
const cdCount = buf.readUInt16LE(eocd + 10);
let cdOff = buf.readUInt32LE(eocd + 16);
let stickerEntry = null;
for (let i = 0; i < cdCount; i++) {
  const nlen = buf.readUInt16LE(cdOff + 28);
  const xlen = buf.readUInt16LE(cdOff + 30);
  const cmlen = buf.readUInt16LE(cdOff + 32);
  const name = buf.toString('utf8', cdOff + 46, cdOff + 46 + nlen);
  if (name === 'stickers.apk') {
    stickerEntry = { lho: buf.readUInt32LE(cdOff + 42), csize: buf.readUInt32LE(cdOff + 20) };
  }
  cdOff += 46 + nlen + xlen + cmlen;
}
assert.ok(stickerEntry, 'stickers.apk central entry');
const lnlen = buf.readUInt16LE(stickerEntry.lho + 26);
const lxlen = buf.readUInt16LE(stickerEntry.lho + 28);
const apk = buf.subarray(stickerEntry.lho + 30 + lnlen + lxlen,
  stickerEntry.lho + 30 + lnlen + lxlen + stickerEntry.csize);

// scan sticker pack dir names from inner zip local headers
const packRe = /assets\/(sticker_[a-z0-9_]+)\//g;
const text = apk.toString('latin1');
const packDirs = new Set();
let m;
while ((m = packRe.exec(text)) !== null) packDirs.add(m[1]);
check('stickers.apk bundles 39 webp sticker pack directories',
  packDirs.size === 39 && text.includes('sticker_dash_planning') &&
  text.includes('sticker_konana_academic'));

const ev = fs.readFileSync(
  'docs/migration/evidence/phase-763-original-covers-sticker-split.md', 'utf8');
check('Phase 763 evidence registers covers + sticker-split inventory',
  ev.includes('stickers.apk') && ev.includes('39') && ev.includes('covers'));

console.log(`D02_ORIGINAL_COVERS_STICKER_SPLIT_OK TOTAL=${checks.length} FAILED=0`);
