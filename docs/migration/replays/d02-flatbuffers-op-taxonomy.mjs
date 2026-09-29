// Phase 1043 — cee Table base + haa 32-op enum + ye9/ka4/exc ifaces
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const cee = readFileSync(D + 'cee.java', 'utf8');
const haa = readFileSync(D + 'haa.java', 'utf8');
const ye9 = readFileSync(D + 'ye9.java', 'utf8');
const ka4 = readFileSync(D + 'ka4.java', 'utf8');
const exc = readFileSync(D + 'exc.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('cee: table fields {I,J,K,L}', cee.includes('public int I') && cee.includes('public int K') && cee.includes('public int L'));
t('cee.b(): uoffset indirect', cee.includes('return this.J.getInt(i) + i;'));
t('cee.c(): vtable slot 0-pad', cee.includes('this.J.getShort(this.K + i)') && cee.includes('return 0;'));
t('cee.d(): vtable bind', cee.includes('this.K = i2;') || cee.includes('byteBuffer.getInt(i)'));
t('cee.e(): UTF-8 string decoder', cee.includes('Invalid UTF-8') && cee.includes('x82.'));
const ops = ['NONE','SET_METADATA','ASSET_CLOUD_PERSISTED','CREATE_PAGE','MODIFY_PAGE','CREATE_RECORDING','MODIFY_RECORDING','INSERT_CHAR','INSERT_STRING','REMOVE_CHAR','REMOVE_CHARS','REVIVE_CHARS','MODIFY_STYLE','MODIFY_PARAGRAPH_STYLE','CLEAR_STYLE','CREATE_INK','ADD_PATH_ELEMENTS','MODIFY_INK','CREATE_SHAPE','MODIFY_SHAPE','CREATE_GROUP','MODIFY_GROUP','CREATE_BLOCK','MODIFY_BLOCK','MODIFY_POSITIONS','DELETE_ENTITIES','TRANSIENT_INTERACTION_ENDED','MODIFY_PDF_FIELD','UPDATE_CHECKBOX','PEER_INTERACTION','CREATE_COMMENT','MODIFY_COMMENT'];
t('haa: all 32 op names present', ops.every(o => haa.includes(o + '((byte)')));
t('haa: 32 byte constants', (haa.match(/\(byte\) -?\d+/g) || []).length === 32);
t('haa: byte field I + nz3 entries', haa.includes('public final byte I') && haa.includes('nz3'));
t('ye9: 6 accessors', (ye9.match(/\(\);/g) || []).length === 6);
t('ka4: single String a()', ka4.includes('String a();'));
t('exc: a1/m/C + A0 unsigned-m order', exc.includes('int a1()') && exc.includes('short m()') && exc.includes('int C()') && exc.includes('& 65535'));
t('exc: A0 compares a1 then m then C', exc.includes('excVar.C() - C()'));
console.log('flatbuffers-op-taxonomy replay: ' + n + '/12 checks green');
