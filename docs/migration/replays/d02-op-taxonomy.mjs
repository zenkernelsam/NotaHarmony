// Phase 1275 — haa 32-op taxonomy + tmf timestamp + sdf entity
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const haa = R('haa.java');
t('haa text ops INSERT/REMOVE/REVIVE', haa.includes('INSERT_CHAR') && haa.includes('REMOVE_CHARS') && haa.includes('REVIVE_CHARS'));
t('haa style ops', haa.includes('MODIFY_STYLE') && haa.includes('MODIFY_PARAGRAPH_STYLE') && haa.includes('CLEAR_STYLE'));
t('haa ink ops', haa.includes('CREATE_INK') && haa.includes('ADD_PATH_ELEMENTS') && haa.includes('MODIFY_INK'));
t('haa shape/group/block ops', haa.includes('CREATE_SHAPE') && haa.includes('CREATE_GROUP') && haa.includes('CREATE_BLOCK') && haa.includes('MODIFY_POSITIONS'));
t('haa pdf/comment/collab ops', haa.includes('MODIFY_PDF_FIELD') && haa.includes('UPDATE_CHECKBOX') && haa.includes('CREATE_COMMENT') && haa.includes('PEER_INTERACTION'));
t('haa 32 ops byte enum', (haa.match(/\(byte\) \d+\)/g)||[]).length >= 30);
const tmf = R('tmf.java');
t('tmf long Comparable timestamp', tmf.includes('implements Comparable') && tmf.includes('long I'));
const sdf = R('sdf.java');
t('sdf entity cee+qo5+mmf', sdf.includes('extends cee implements ka4') && sdf.includes('qo5') && sdf.includes('mmf'));
const xwd = R('xwd.java');
t('xwd Struct ByteBuffer', xwd.includes('ByteBuffer J') && xwd.includes('int I'));
const uq9 = R('uq9.java');
t('uq9 references tmf/haa/sdf', uq9.includes('tmf') && uq9.includes('haa') && uq9.includes('sdf'));
console.log('op-taxonomy replay: ' + n + '/10 checks green');
