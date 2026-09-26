// Phase 816 replay: locale-split translation coverage matrix.
// Parses each config.<locale>.apk resources.arsc global string pool;
// pins 15 full locales (~1830-1950), my=93 stub, en/xxhdpi marker
// splits, and zh-Hans app strings inside config.zh.apk.
import fs from 'node:fs';
import zlib from 'node:zlib';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability';
const XAPK = `${ROOT}/Notability_1.4.2/Notability%3A+AI+Note+Workspace_1.4.2_apkcombo.com.xapk`;

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

// --- minimal zip CD parse ---
function cdEntries(buf) {
  const eocd = buf.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  const count = buf.readUInt16LE(eocd + 10);
  let off = buf.readUInt32LE(eocd + 16);
  const out = [];
  for (let i = 0; i < count; i++) {
    const nlen = buf.readUInt16LE(off + 28);
    const xlen = buf.readUInt16LE(off + 30);
    const cmlen = buf.readUInt16LE(off + 32);
    out.push({
      name: buf.toString('utf8', off + 46, off + 46 + nlen),
      method: buf.readUInt16LE(off + 10),
      csize: buf.readUInt32LE(off + 20),
      lho: buf.readUInt32LE(off + 42),
    });
    off += 46 + nlen + xlen + cmlen;
  }
  return out;
}
function member(buf, e) {
  const nlen = buf.readUInt16LE(e.lho + 26);
  const xlen = buf.readUInt16LE(e.lho + 28);
  const raw = buf.subarray(e.lho + 30 + nlen + xlen,
    e.lho + 30 + nlen + xlen + e.csize);
  return e.method === 8 ? zlib.inflateRawSync(raw) : raw;
}

// --- arsc global string pool ---
function arscStrings(arsc) {
  const hs = arsc.readUInt16LE(2);
  const o = hs;
  const sc = arsc.readUInt32LE(o + 8);
  const flags = arsc.readUInt32LE(o + 16);
  const so = arsc.readUInt32LE(o + 20);
  const offs = [];
  for (let i = 0; i < sc; i++) offs.push(arsc.readUInt32LE(o + 28 + 4 * i));
  const base = o + so;
  const utf8 = (flags & 0x100) !== 0;
  return offs.map(off => {
    let p = base + off;
    if (utf8) {
      let u16l = arsc[p++];
      if (u16l & 0x80) u16l = ((u16l & 0x7f) << 8) | arsc[p++];
      let u8l = arsc[p++];
      if (u8l & 0x80) u8l = ((u8l & 0x7f) << 8) | arsc[p++];
      return arsc.subarray(p, p + u8l).toString('utf8');
    }
    let l = arsc.readUInt16LE(p); p += 2;
    if (l & 0x8000) { l = ((l & 0x7fff) << 16) | arsc.readUInt16LE(p); p += 2; }
    return arsc.subarray(p, p + 2 * l).toString('utf16le');
  });
}

const xapk = fs.readFileSync(XAPK);
const entries = cdEntries(xapk);
const poolSizes = {};
for (const e of entries) {
  if (!e.name.startsWith('config.') || !e.name.endsWith('.apk')) continue;
  const inner = member(xapk, e);
  const ie = cdEntries(inner).find(c => c.name === 'resources.arsc');
  if (!ie) continue;
  const arsc = member(inner, ie);
  poolSizes[e.name] = arsc.readUInt32LE(arsc.readUInt16LE(2) + 8);
}

const FULL = ['ar','de','es','fr','hi','in','it','ja','ko','pt','ru','th','tr','vi','zh'];
check('15 full locales each carry ~1800-2000 strings',
  FULL.every(l => (poolSizes[`config.${l}.apk`] || 0) >= 1800 &&
                  (poolSizes[`config.${l}.apk`] || 0) <= 2000),
  FULL.map(l => `${l}:${poolSizes[`config.${l}.apk`]}`).join(','));
check('config.my is a stub locale (93 strings)',
  poolSizes['config.my.apk'] === 93, poolSizes['config.my.apk']);
check('config.en + config.xxhdpi are marker splits (<200 strings)',
  poolSizes['config.en.apk'] === 141 &&
  poolSizes['config.xxhdpi.apk'] === 48);

// zh split deep-check: decode pool, confirm zh-Hans app strings.
const zhE = entries.find(e => e.name === 'config.zh.apk');
const zhInner = member(xapk, zhE);
const zhArsc = member(zhInner,
  cdEntries(zhInner).find(c => c.name === 'resources.arsc'));
const zh = arscStrings(zhArsc);
const hasCjk = s => [...s].some(c => c >= '一' && c <= '鿿');
const cjk = zh.filter(hasCjk);
check('zh pool: 1,936 strings, ~96% CJK',
  zh.length === 1936 && cjk.length >= 1800,
  `${cjk.length}/${zh.length}`);
check('zh app strings are Simplified (笔记/文件夹/录音 forms)',
  zh.some(s => s.includes('笔记')) && zh.some(s => s.includes('文件夹')),
  'no zh-Hans app forms found');
check('zh pool retains vendor zh-Hant (GMS/Samsung) strings',
  zh.some(s => s.includes('服務') || s.includes('裝置')),
  'no zh-Hant vendor forms found');

console.log(`\nlocale-coverage replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
