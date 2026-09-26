// Phase 839 — com.gingerlabs 包骨架闭合
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const R = 'C:/Users/Cisco He/Desktop/Notability';
const pkgs = (v) => {
  const out = [];
  const base = `${R}/decompiled_${v}/sources/`.replace(/\\/g, '/');
  const walk = (d) => { for (const e of readdirSync(d, { withFileTypes: true })) { const p = join(d, e.name); if (e.isDirectory()) { const rel = p.replace(/\\/g, '/').replace(base, ''); out.push(rel); walk(p); } } };
  walk(`${R}/decompiled_${v}/sources/com/gingerlabs`);
  return out.sort();
};
const p101 = pkgs('1.0.1'), p103 = pkgs('1.0.3'), p142 = pkgs('1.4.2');
const added142 = p142.filter(p => !p103.includes(p));

const results = [];
const ck = (n, ok) => results.push([n, ok]);

ck('1.0.1 包数=72', p101.length === 72);
ck('1.0.3 包数=72', p103.length === 72);
ck('1.0.1↔1.0.3 零差', p101.join() === p103.join());
ck('1.4.2 包数=94', p142.length === 94);
ck('1.4.2 新增恰 22 包', added142.length === 22);
ck('新增含 calendar/gallery/stickers/notelimit/hwr', ['data/calendar', 'data/gallery', 'feature/note/stickers', 'data/library/state/notelimit', 'data/handwritingrecognition/hwr'].every(p => added142.some(a => a.endsWith(p))));

// 叶子类断言
const read = (p) => readFileSync(join(R, 'decompiled_1.4.2/sources', p), 'utf8');
ck('NoteLimitRefusedException 消息', read('com/gingerlabs/notability/data/library/state/notelimit/NoteLimitRefusedException.java').includes('Note limit reached'));
ck('samsungbilling gateway 4 异常', readdirSync(join(R, 'decompiled_1.4.2/sources/com/gingerlabs/notability/data/samsungbilling/gateway')).length === 4);
ck('BackgroundMaintenanceWorker=CoroutineWorker', read('com/gingerlabs/notability/domain/maintenance/BackgroundMaintenanceWorker.java').includes('CoroutineWorker'));
ck('flatbuffers ValidationException', read('com/gingerlabs/notability/core/flatbuffers/ValidationException.java').includes('Exception'));
ck('google/flatbuffers 仅剩骨架', readdirSync(join(R, 'decompiled_1.4.2/sources/com/google/flatbuffers')).length <= 2);
ck('Harmony 无 noteLimit 实现', !(() => { try { return readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/NoteLimitGate.ets', 'utf8'); } catch { return false; } })());

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
