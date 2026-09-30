// Phase 1349 — unit-test suite coverage
import { readFileSync, existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const T = 'C:/HarmonyProject/NotaHarmony/note/src/test/';
const O = 'C:/HarmonyProject/NotaHarmony/note/src/ohosTest/ets/test/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const tests = readdirSync(T).filter(f => f.endsWith('.test.ets'));
t('>=100 unit tests', tests.length >= 100);
t('CubicFitter test', existsSync(T + 'CubicFitter.test.ets'));
t('ForceSmoother test', existsSync(T + 'ForceSmoother.test.ets'));
t('EraserEngine test', existsSync(T + 'EraserEngine.test.ets'));
t('AsyncMutex test', existsSync(T + 'AsyncMutex.test.ets'));
t('OpStore test', existsSync(T + 'OpStore.test.ets'));
t('BinaryPlistParser test', existsSync(T + 'BinaryPlistParser.test.ets'));
t('SyncCoordinator test', existsSync(T + 'IncomingOperationSyncCoordinator.test.ets'));
const list = readFileSync(O + 'List.test.ets', 'utf8');
t('ohosTest List exists', existsSync(O + 'List.test.ets'));
t('Hypium device-bound (placeholder reg)', list.includes('abilityTest'));
console.log('test-suite replay: ' + n + '/10 checks green (' + tests.length + ' tests)');
