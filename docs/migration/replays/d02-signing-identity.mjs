// Phase 814 replay: APK signing-block + signer-certificate identity.
// Parses each base APK's APK Sig Block, extracts the v3 signer cert,
// and pins that all three versions share one signing identity.
import fs from 'node:fs';
import crypto from 'node:crypto';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability';
const APKS = {
  '1.0.1': `${ROOT}/Notability_1.0.1/com.gingerlabs.notability.apk`,
  '1.0.3': `${ROOT}/Notability_1.0.3/com.gingerlabs.notability.apk`,
  '1.4.2': `${ROOT}/Notability_1.4.2/com.gingerlabs.notability.apk`,
};

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

function sigPairs(d) {
  const magic = Buffer.from('APK Sig Block 42');
  const i = d.lastIndexOf(magic);
  if (i < 0) return null;
  const sz = Number(d.readBigUInt64LE(i - 8));
  const blkStart = i + 16 - (sz + 8) + 8;
  const out = new Map();
  let off = blkStart;
  while (off < i - 8) {
    const plen = Number(d.readBigUInt64LE(off));
    const pid = d.readUInt32LE(off + 8);
    out.set(pid, d.subarray(off + 12, off + 8 + plen));
    off += 8 + plen;
  }
  return out;
}

function li(b, o) { return b.readUInt32LE(o); }
function certsFromV3(blob) {
  let o = 0;
  const n = li(blob, o); o += 4;
  const signers = blob.subarray(o, o + n);
  const res = [];
  let o2 = 0;
  while (o2 < signers.length) {
    const sn = li(signers, o2); o2 += 4;
    const s = signers.subarray(o2, o2 + sn); o2 += sn;
    let p = 0;
    const dn = li(s, p); p += 4;
    const sd = s.subarray(p, p + dn);
    let q = 0;
    const dgn = li(sd, q); q += 4 + dgn;
    const cn = li(sd, q); q += 4;
    const cb = sd.subarray(q, q + cn);
    let r = 0;
    while (r < cb.length) {
      const cl = li(cb, r); r += 4;
      res.push(cb.subarray(r, r + cl)); r += cl;
    }
  }
  return res;
}

const V2 = 0x7109871a, V3 = 0xf05368c0, STAMP = 0x6dff800d;
const certs = {};
for (const [v, p] of Object.entries(APKS)) {
  const d = fs.readFileSync(p);
  const pairs = sigPairs(d);
  check(`${v}: APK Sig Block present with v2+v3+stamp`,
    !!pairs && pairs.has(V2) && pairs.has(V3) && pairs.has(STAMP));
  check(`${v}: channel + play metadata blocks present`,
    pairs.has(0x2146444e) && pairs.has(0x42726577));
  const cs = certsFromV3(pairs.get(V3));
  certs[v] = cs.map(c => crypto.createHash('sha256').update(c).digest('hex'));
  check(`${v}: single v3 signer cert`, cs.length === 1, String(cs.length));
}

check('signer identity identical across 1.0.1/1.0.3/1.4.2',
  certs['1.0.1'][0] === certs['1.0.3'][0] &&
  certs['1.0.3'][0] === certs['1.4.2'][0]);
check('signer cert sha256 prefix = 8fb7a01443b50be6',
  certs['1.4.2'][0].startsWith('8fb7a01443b50be6'),
  certs['1.4.2'][0]);

console.log(`\nsigning-identity replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
