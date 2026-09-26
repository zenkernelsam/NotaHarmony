// D02 原版 1.4.2 .brushpack 格式 — Phase 762（ADR-0708 版本差待审细化）
// 钉住 brushpacks/ ZIP 容器结构、manifest schema、proto gzip 包层与五包清单。
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/assets/brushpacks';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('brushpacks asset root exists (1.4.2-only surface)', fs.existsSync(base));

const packs = fs.readdirSync(base).filter(f => f.endsWith('.brushpack'));
check('exactly five bundled brushpacks', packs.length === 5);

// minimal local-zip reader: locate End of Central Directory, walk entries
const zipEntries = file => {
  const buf = fs.readFileSync(file);
  const eocd = buf.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  const total = buf.readUInt16LE(eocd + 10);
  let off = buf.readUInt32LE(eocd + 16);
  const out = new Map();
  for (let i = 0; i < total; i++) {
    const csize = buf.readUInt32LE(off + 20);
    const nlen = buf.readUInt16LE(off + 28);
    const xlen = buf.readUInt16LE(off + 30);
    const cmolen = buf.readUInt16LE(off + 32);
    const name = buf.toString('utf8', off + 46, off + 46 + nlen);
    const lho = buf.readUInt32LE(off + 42);
    const lnlen = buf.readUInt16LE(lho + 26);
    const lxlen = buf.readUInt16LE(lho + 28);
    const comp = buf.readUInt16LE(lho + 8);
    const dataOff = lho + 30 + lnlen + lxlen;
    const raw = buf.subarray(dataOff, dataOff + csize);
    out.set(name, comp === 8 ? zlib.inflateRawSync(raw) : raw);
    off += 46 + nlen + xlen + cmolen;
  }
  return out;
};

const rainbow = zipEntries(path.join(base, 'rainbow.brushpack'));
check('brushpack is a ZIP with manifest.json + brush_family.proto + two previews',
  rainbow.has('manifest.json') && rainbow.has('brush_family.proto') &&
  rainbow.has('preview_well.png') && rainbow.has('preview_selection.png'));

const manifest = JSON.parse(rainbow.get('manifest.json').toString('utf8'));
check('manifest schema carries displayName/fallbackColor/fallbackWidthDp/tintable',
  manifest.displayName === 'Rainbow' && manifest.fallbackColor === '#666666' &&
  manifest.fallbackWidthDp === 4 && manifest.tintable === true);

const proto = rainbow.get('brush_family.proto');
check('brush_family.proto is gzip-wrapped protobuf',
  proto[0] === 0x1f && proto[1] === 0x8b);
const inflated = zlib.gunzipSync(proto);
check('inflated proto carries the brush family id string',
  inflated.includes('fun-a-unstable'));

const rocket = JSON.parse(zipEntries(path.join(base, 'droidrocket.brushpack'))
  .get('manifest.json').toString('utf8'));
check('multiply-tint packs carry tintBlendMode/tintAlpha',
  rocket.tintBlendMode === 'multiply' && rocket.tintAlpha === 1);

const ev = fs.readFileSync(
  'docs/migration/evidence/phase-762-original-brushpack-format.md', 'utf8');
check('Phase 762 evidence registers container + five-pack manifest',
  ev.includes('brush_family.proto') && ev.includes('fun-a-unstable') &&
  ev.includes('droidrocket'));

console.log(`D02_ORIGINAL_BRUSHPACK_FORMAT_OK TOTAL=${checks.length} FAILED=0`);
