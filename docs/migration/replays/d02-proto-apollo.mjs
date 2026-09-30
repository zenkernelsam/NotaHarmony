// Phase 1277 — protobuf-lite codegen + Apollo exception taxonomy
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const R = f => readFileSync(S + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const z6h = R('defpackage/z6h.java');
t('z6h MessageLite a()→byte[]', z6h.includes('byte[] a()') && z6h.includes('int b(i9h'));
const x7h = R('defpackage/x7h.java');
t('x7h Builder Cloneable+mergeFrom', x7h.includes('implements Cloneable') && x7h.includes('c(byte[] bArr, s7h'));
const z7h = R('defpackage/z7h.java');
t('z7h GeneratedMessageLite parseFrom', z7h.includes('c(z7h z7hVar, byte[] bArr, s7h'));
t('z7h dynamicMethod o(Method)', z7h.includes('Object o(Method method, z7h'));
const ibj = R('defpackage/ibj.java'), fbj = R('defpackage/fbj.java');
t('ibj z7h message', ibj.includes('extends z7h'));
t('fbj x7h builder', fbj.includes('extends x7h'));
const ae = R('com/apollographql/apollo/exception/ApolloException.java');
t('ApolloException sealed', ae.includes('abstract class ApolloException extends RuntimeException'));
t('Apollo subtype list', ae.includes('ApolloGraphQLException') && ae.includes('CacheMissException'));
const nd = R('com/apollographql/apollo/exception/NoDataException.java');
t('NoDataException', nd.includes('extends ApolloException'));
t('normalized sql cache init', existsSync(S + 'com/apollographql/apollo/cache/normalized/sql/ApolloInitializer.java'));
console.log('proto-apollo replay: ' + n + '/10 checks green');
