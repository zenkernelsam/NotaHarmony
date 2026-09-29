// Phase 986 — yk9 export producer + fsi.P filter + haa full enum
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const yk9 = readFileSync(`${ROOT}/yk9.java`, 'utf8');
const fsi = readFileSync(`${ROOT}/fsi.java`, 'utf8');
const haa = readFileSync(`${ROOT}/haa.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// haa = complete 32-ordinal op enum
for (const [name, ord] of [['NONE',0],['SET_METADATA',1],['ASSET_CLOUD_PERSISTED',2],['CREATE_PAGE',3],['MODIFY_PAGE',4],['CREATE_RECORDING',5],['MODIFY_RECORDING',6],['INSERT_CHAR',7],['INSERT_STRING',8],['REMOVE_CHAR',9],['REMOVE_CHARS',10],['REVIVE_CHARS',11],['MODIFY_STYLE',12],['MODIFY_PARAGRAPH_STYLE',13],['CLEAR_STYLE',14],['CREATE_INK',15],['ADD_PATH_ELEMENTS',16],['MODIFY_INK',17],['CREATE_SHAPE',18],['MODIFY_SHAPE',19],['CREATE_GROUP',20],['MODIFY_GROUP',21],['CREATE_BLOCK',22],['MODIFY_BLOCK',23],['MODIFY_POSITIONS',24],['DELETE_ENTITIES',25],['TRANSIENT_INTERACTION_ENDED',26],['MODIFY_PDF_FIELD',27],['UPDATE_CHECKBOX',28],['PEER_INTERACTION',29],['CREATE_COMMENT',30],['MODIFY_COMMENT',31]])
  ok(new RegExp(name + '\\(\\(byte\\) ' + ord + '\\)').test(haa), `haa[${ord}] = ${name}`);

// fsi.P — export filter (transient + 26/29 excluded)
ok(/if \(uq9Var\.o\(\) != null\)[\s\S]{0,30}return true/.test(fsi), 'fsi.P: transientInteraction non-null -> exclude');
ok(/case 26:\s*case zn5\.ENABLE_QUALIFIED_ID_JOIN_INDEX_V3_FIELD_NUMBER \/\* 29 \*\/:\s*return true/.test(fsi), 'fsi.P: ordinals 26+29 excluded');

// yk9 — export producer
ok(/if \(!fsi\.P\(\(uq9\) next\)\)/.test(yk9), 'yk9: fsi.P filter');
ok(/au1\.K1\(arrayList, ldj\.G1\(new k79\(3\), new k79\(4\)\)\)/.test(yk9), 'yk9: dual-key sort k79(3)+k79(4)');
ok(/a aVarA = dk4\.a\(c8dVar2\)/.test(yk9), 'yk9: pooled builder dk4.a');
ok(/wtf\.c\(ttfVarA0\)/.test(yk9), 'yk9: wtf.c noteId->utf');
ok(/aVarA\.p\(q4j\.c\(aVarA, utfVarC2, utfVarC, s, ttfVarB\.toString\(\), jA, ttfVarE\.toString\(\), size, ny6Var\)\)/.test(yk9), 'yk9: q4j.c write+p finish');
ok(/byteBufferWrap\.order\(ByteOrder\.LITTLE_ENDIAN\);\s*r29Var\.d\(/.test(yk9), 'yk9: LE re-read into r29');
ok(/ybg\.c\(r29Var\)/.test(yk9), 'yk9: validate re-read bundle');
ok(/byte\[\] bArrB = ree\.b\(r29Var\)/.test(yk9), 'yk9: ree.b second serialization');

// asset manifest collection
ok(/uq9Var\.r\(sdfVar\) == null && \(z \|\| uq9Var\.m\(\) != haa\.CREATE_RECORDING\)/.test(yk9), 'yk9: transient skip + recording gate');
ok(/\(\(l2d\) z5c\.x\(uq9Var\)\)\.p\(\)[\s\S]{0,400}new cba\(sw9VarL\)/.test(yk9), 'yk9: SET_METADATA->pageBackground->PDFAsset');
ok(/dp5VarM[\s\S]{0,200}new cp5\(dp5VarM\)/.test(yk9), 'yk9: CREATE_BLOCK->ImageAsset');
ok(/u0j\.d\(\(ge8\)/.test(yk9) && /kaj\.a\(\(yn2\)/.test(yk9), 'yk9: MODIFY_PAGE/CREATE_RECORDING asset extraction');
ok(/mx7Var\.containsKey\(ua0VarJ\)/.test(yk9) && /mx7Var\.put\(ua0VarJ, cbaVar\.a\(\)\)/.test(yk9), 'yk9: ua0-keyed asset manifest');

console.log(`\nexport-bundle replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
