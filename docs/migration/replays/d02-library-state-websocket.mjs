// Phase 849 — LibraryStateWebSocket 实时同步协议
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage';
const results = [];
const ck = (n, ok) => results.push([n, ok]);
const h69 = readFileSync(join(S, 'h69.java'), 'utf8');
const yca = readFileSync(join(S, 'yca.java'), 'utf8');
const x59 = readFileSync(join(S, 'x59.java'), 'utf8');

// 连接模型
ck('LibraryStateWebSocket 命名', h69.includes('"LibraryStateWebSocket"'));
ck(':443 /metadata 端点', h69.includes('":443"') && h69.includes('"/metadata"'));
ck('per-path socket 缓存', yca.includes('R.put(path, jmgVar)') || yca.includes('R.get(path)'));

// 事件面
ck('构造期 disconnect/invalid-credentials/lame-duck',
  yca.includes('"disconnect"') && yca.includes('"invalid-credentials"') && yca.includes('"lame-duck-server-shutdown"'));
ck('业务订阅 connect/connect_error/change-ack/partial-update',
  h69.includes('"connect"') && h69.includes('"connect_error"') && h69.includes('"change-ack"') && h69.includes('"partial-update"'));
ck('发送 reset-sequence-id + change', h69.includes('"reset-sequence-id"') && h69.includes('"change"'));
ck('ack 超时回路', h69.includes('Timeout waiting for change-ack'));
ck('partial-update 解析失败日志', x59.includes('Failed to parse partial-update'));

// upsert-note 负载
for (const k of ['"upsert-note"', '"titleOp"', '"thumbnailOp"', '"linkShareSettings"', '"title"', '"createdAt"', '"updatedAt"', '"isFavorited"', '"lastOpened"', '"deletedAt"', '"subjectId"', '"timestamp"', '"siteId"']) {
  ck(`upsert-note 字段 ${k}`, h69.includes(k));
}
ck('linkShareSettings 缺失告警', h69.includes('Missing linkShareSettings in upsert-note'));

// Harmony 无 WebSocket 同步面
let found = false;
const walk = (d) => { try { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walk(p); else if (f.name.endsWith('.ets')) { const t = readFileSync(p, 'utf8'); if (/change-ack|partial-update|lame-duck|invalid-credentials/.test(t)) found = true; } } } catch {} };
walk('C:/HarmonyProject/NotaHarmony/note/src/main/ets');
ck('Harmony 无 socket.io 事件面', !found);

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
