// Phase 850 — NoteOpsWebSocket 笔记 ops 实时通道
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage';
const results = [];
const ck = (n, ok) => results.push([n, ok]);
const xgb = readFileSync(join(S, 'xgb.java'), 'utf8');

// 通道模型
ck('NoteOpsWebSocket 命名', xgb.includes('"NoteOpsWebSocket"'));
ck('/open-note/<id> 路径', xgb.includes('"/open-note/"'));
ck(':443 端点', xgb.includes('":443"'));

// 事件面
ck('订阅 peer-event/receive-ops', xgb.includes('"peer-event"') && xgb.includes('"receive-ops"'));
ck('acknowledge-appended-ops', xgb.includes('"acknowledge-appended-ops"'));
ck('connect/connect_error', xgb.includes('"connect"') && xgb.includes('"connect_error"'));
ck('message 事件', xgb.includes('"message"'));
ck('重建反注册 K0×3', (xgb.match(/K0\("(peer-event|receive-ops|acknowledge-appended-ops)"\)/g) || []).length === 3);
ck('expectedAckReply 缺失日志', xgb.includes('Missing expectedAckReply in receive-ops'));
ck('断开 r() 关闭', xgb.includes('dgeVar.r()'));

// Harmony：ack 契约已移植，传输层缺位
const coord = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/IncomingOperationSyncCoordinator.ets', 'utf8');
ck('Harmony expectedAckReply 契约已移植', coord.includes('expectedAckReply') && coord.includes('acknowledge'));
let found = false;
const walk = (d) => { try { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walk(p); else if (f.name.endsWith('.ets')) { const t = readFileSync(p, 'utf8'); if (/acknowledge-appended-ops|peer-event|open-note\//.test(t)) found = true; } } } catch {} };
walk('C:/HarmonyProject/NotaHarmony/note/src/main/ets');
ck('Harmony 无 socket 传输层', !found);

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
