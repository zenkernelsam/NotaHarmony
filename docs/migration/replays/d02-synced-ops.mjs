// Phase 840 — data/note/ops 同步操作层
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability/data/note/ops';
const coord = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/OperationSyncCoordinator.ets', 'utf8');

const results = [];
const ck = (n, ok) => results.push([n, ok]);

// 结构
const synced = readdirSync(join(S, 'synced')).filter(f => f.endsWith('.java'));
const db = readdirSync(join(S, 'database'));
ck('synced/ 恰 6 异常类', synced.length === 6);
ck('database/ NoteBundleMetadata', db.includes('NoteBundleMetadataDatabase.java'));

// 6 异常类型全在
const exc = ['AccessDeniedException', 'CorruptedSyncedOpException', 'NoteHasNoOpsException',
  'NoteOpsGoneException', 'NoteOpsNotFoundException', 'StaleSyncedNoteException'];
ck('六类同步失败类型齐全', exc.every(e => synced.includes(e + '.java')));

// 每类确为 Exception 子类
for (const e of exc) {
  const src = readFileSync(join(S, 'synced', e + '.java'), 'utf8');
  ck(`${e} 为异常类`, /extends (Exception|RuntimeException|\w+Exception)/.test(src));
}
ck('Gone ⊂ NotFound 层级', /class NoteOpsGoneException extends NoteOpsNotFoundException/.test(readFileSync(join(S, 'synced/NoteOpsGoneException.java'), 'utf8')));

// Harmony 侧：非类型化
ck('Harmony 有 op 校验错误', (coord.match(/throw new Error/g) || []).length >= 5);
ck('Harmony 无类型化同步异常', !/class \w*(AccessDenied|Corrupted|Stale|Gone|NotFound|NoOps)\w*/.test(coord));
ck('Harmony 有上传 ack 校验', coord.includes('upload acknowledgement'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
