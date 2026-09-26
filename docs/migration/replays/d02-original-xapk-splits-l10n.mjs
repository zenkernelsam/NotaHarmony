// D02 原版 1.4.2 XAPK 分包与本地化面 — Phase 795
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const X103 = 'C:/Users/Cisco He/Desktop/Notability/Notability_1.0.3/Notability_+AI+Note+Workspace_1.0.3_APKPure.xapk';
const X142 = 'C:/Users/Cisco He/Desktop/Notability/Notability_1.4.2/Notability%3A+AI+Note+Workspace_1.4.2_apkcombo.com.xapk';
const RES = 'C:/HarmonyProject/NotaHarmony/note/src/main/resources';

const zipEntries = (file) => {
  const b = fs.readFileSync(file);
  const eocd = b.lastIndexOf(Buffer.from('PK\x05\x06'));
  const n = b.readUInt16LE(eocd + 10);
  let off = b.readUInt32LE(eocd + 16);
  const entries = new Map();
  for (let i = 0; i < n; i++) {
    const nl = b.readUInt16LE(off + 28);
    const name = b.slice(off + 46, off + 46 + nl).toString();
    entries.set(name, {
      csz: b.readUInt32LE(off + 20), cm: b.readUInt16LE(off + 10),
      lh: b.readUInt32LE(off + 42),
    });
    off += 46 + nl + b.readUInt16LE(off + 30) + b.readUInt16LE(off + 32);
  }
  return { b, entries };
};
const readEntry = ({ b, entries }, name) => {
  const e = entries.get(name);
  const ln = b.readUInt16LE(e.lh + 26), le = b.readUInt16LE(e.lh + 28);
  let d = b.slice(e.lh + 30 + ln + le, e.lh + 30 + ln + le + e.csz);
  return e.cm === 8 ? zlib.inflateRawSync(d) : d;
};

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const z103 = zipEntries(X103), z142 = zipEntries(X142);

check('1.0.3 xapk = 4 splits + manifest (no locale splits)',
  z103.entries.size === 5
  && z103.entries.has('com.gingerlabs.notability.apk')
  && [...z103.entries.keys()].filter((k) => /^config\.[a-z]{2}\.apk$/.test(k)).length === 1);
check('1.4.2 xapk = base + 17 locale + density/abi + stickers splits',
  z142.entries.has('stickers.apk')
  && [...z142.entries.keys()].filter((k) => /^config\.[a-z]{2}\.apk$/.test(k)).length === 17);
check('manifest.json: vc1040002, minSdk 32, targetSdk 36',
  (() => {
    const m = JSON.parse(readEntry(z142, 'manifest.json').toString());
    return m.version_code === '1040002' && m.version_name === '1.4.2'
      && m.min_sdk_version === '32' && m.target_sdk_version === '36'
      && m.split_configs.length === 20;
  })());
check('config.zh.apk carries compiled resources.arsc (~205KB)',
  (() => {
    const zh = zipEntriesFromBuffer(readEntry(z142, 'config.zh.apk'));
    return zh.entries.has('resources.arsc')
      && zh.entries.get('resources.arsc').csz > 200000;
  })());
check('Harmony resources: base(en) + zh_CN + dark + rawfile',
  fs.existsSync(path.join(RES, 'base'))
  && fs.existsSync(path.join(RES, 'zh_CN', 'element', 'string.json'))
  && fs.existsSync(path.join(RES, 'dark'))
  && fs.existsSync(path.join(RES, 'rawfile')));
check('Harmony zh_CN covers ~all base strings',
  (() => {
    const base = JSON.parse(fs.readFileSync(
      path.join(RES, 'base', 'element', 'string.json'), 'utf8')).string.length;
    const zh = JSON.parse(fs.readFileSync(
      path.join(RES, 'zh_CN', 'element', 'string.json'), 'utf8')).string.length;
    return zh >= base - 5;
  })());

function zipEntriesFromBuffer(b) {
  const eocd = b.lastIndexOf(Buffer.from('PK\x05\x06'));
  const n = b.readUInt16LE(eocd + 10);
  let off = b.readUInt32LE(eocd + 16);
  const entries = new Map();
  for (let i = 0; i < n; i++) {
    const nl = b.readUInt16LE(off + 28);
    const name = b.slice(off + 46, off + 46 + nl).toString();
    entries.set(name, { csz: b.readUInt32LE(off + 20) });
    off += 46 + nl + b.readUInt16LE(off + 30) + b.readUInt16LE(off + 32);
  }
  return { b, entries };
}

console.log(`xapk-splits-l10n replay: ${checks.length}/${checks.length} checks green`);
