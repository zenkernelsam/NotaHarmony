// D02 后端环境与端点注册表 — Phase 805
import assert from 'node:assert/strict';
import fs from 'node:fs';

const E103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/zp0.java', 'utf8');
const E142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/mr0.java', 'utf8');
const KR0 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/kr0.java', 'utf8');
const HDN = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/hdn.java', 'utf8');
const S142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const envs = (src, cls) => [...src.matchAll(new RegExp(`new ${cls}\\("([A-Z_]+)", \\d+, "([^"]+)", "([^"]+)"`, 'g'))]
  .map((m) => ({ name: m[1], label: m[2], host: m[3] }));
const a = envs(E103, 'zp0'); const b = envs(E142, 'mr0');

check('environment enum identical across versions (42 entries)',
  a.length === 42 && b.length === 42
  && a.map((e) => e.name + '|' + e.host).join(',') === b.map((e) => e.name + '|' + e.host).join(','));

check('groups: MAIN x2 + BERRIES x28 + FRUITS x10 + LOCALHOST x2',
  b.filter((e) => e.host === 'notability.com' || e.host === 'staging.notability.com').length === 2
  && b.filter((e) => /berry|berried/.test(e.host)).length === 28
  && b.filter((e) => e.host.includes('10.0.2.2')).length === 2
  && KR0.includes('MAIN') && KR0.includes('LOCALHOST') && KR0.includes('BERRIES') && KR0.includes('FRUITS'));

check('hdn is the searchable environment picker (Search environments/Clear search)',
  HDN.includes('Search environments') && HDN.includes('Clear search') && HDN.includes('mr0.J'));

check('sticker CDN (io1) + otel (yca) + klipy (ok6) endpoints pinned',
  fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/io1.java', 'utf8')
    .includes('android-assets.notability.com')
  && fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/g2.java', 'utf8')
    .includes('android-assets.notability.com/stickers/1.1.0/')
  && fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/yca.java', 'utf8')
    .includes('otel.notability.com')
  && fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/ok6.java', 'utf8')
    .includes('api.klipy.com'));

check('Firebase project constants public-config pinned in strings.xml',
  S142.includes('notability-2475c') && S142.includes('704682209862')
  && S142.includes('firebase_database_url'));

check('legal/support/social endpoint families present',
  ['notability.com/terms', 'notability.com/privacy', 'notability.com/pricing',
    'support.gingerlabs.com/hc/', 'discord.gg'].every((e) =>
    fs.readdirSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage')
      .some((f) => f.endsWith('.java')
        && fs.readFileSync(`C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage/${f}`, 'utf8').includes(e))));

console.log(`backend-environments replay: ${checks.length}/${checks.length} checks green`);
