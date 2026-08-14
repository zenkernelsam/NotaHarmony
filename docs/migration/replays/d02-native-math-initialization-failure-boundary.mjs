import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const originalEngine = original('defpackage/s18.java');
const originalNative = original('com/gingerlabs/notability/core/glmath/GLMathNative.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const harmonyEngine = read('note/src/main/ets/rendering/OriginalMathEngine.ets');
const initializeStart = native.indexOf('napi_value Initialize(');
const measureStart = native.indexOf('\nnapi_value Measure(', initializeStart);
const cleanupStart = native.indexOf('void Cleanup(');
const initModuleStart = native.indexOf('\nnapi_value Init(', cleanupStart);
const initialize = native.slice(initializeStart, measureStart);
const cleanup = native.slice(cleanupStart, initModuleStart);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original native initialization contract returns a boolean',
  /native boolean nativeInit\(String resPath\)/.test(originalNative));
check('original engine catches native initialization failures and degrades to false',
  /nativeInit\(absolutePath\)/.test(originalEngine) &&
  /catch \(Throwable th\)[\s\S]*?new ozb\(th\)/.test(originalEngine) &&
  /GLMath resource extraction failed[\s\S]*?ozbVar = Boolean\.FALSE/.test(originalEngine));
check('original engine caches both successful and failed initialization results',
  /Boolean bool = this\.c;[\s\S]*?if \(bool != null\)[\s\S]*?return bool\.booleanValue\(\)/.test(originalEngine) &&
  /this\.c = bool2/.test(originalEngine));

check('Harmony native state records whether initialization was already attempted',
  /bool gInitializationAttempted = false;/.test(native));
check('invalid N-API arguments are rejected before consuming the single attempt',
  initialize.indexOf('!ReadString(env, arguments[0], root)') <
    initialize.indexOf('if (!gInitializationAttempted)'));
check('Harmony consumes the attempt before entering third-party initialization',
  /if \(!gInitializationAttempted\)[\s\S]*?gInitializationAttempted = true;[\s\S]*?try \{[\s\S]*?tex::LaTeX::init\(root\)/
    .test(initialize));
check('Harmony commits initialized state only after a non-empty resolved resource root',
  /tex::LaTeX::init\(root\);[\s\S]*?std::string resourceRoot = tex::LaTeX::getResRootPath\(\);[\s\S]*?if \(!resourceRoot\.empty\(\)\)[\s\S]*?gResourceRoot = std::move\(resourceRoot\);[\s\S]*?gInitialized = true;/.test(initialize));
check('standard initialization exceptions fail closed without crossing N-API',
  /catch \(const std::exception &\)[\s\S]*?gInitialized = false;[\s\S]*?gResourceRoot\.clear\(\)/.test(initialize));
check('unknown initialization exceptions also fail closed',
  /catch \(\.\.\.\)[\s\S]*?gInitialized = false;[\s\S]*?gResourceRoot\.clear\(\)/.test(initialize));
check('subsequent calls return the cached state instead of retrying partial initialization',
  (initialize.match(/tex::LaTeX::init\(root\)/g) ?? []).length === 1 &&
  /if \(!gInitializationAttempted\)/.test(initialize));
check('boolean result creation is checked and reflects only committed state',
  /napi_value result = nullptr;/.test(initialize) &&
  /napi_get_boolean\(env, gInitialized, &result\) != napi_ok/.test(initialize));
check('Harmony ArkTS treats native false as an unavailable engine',
  /this\.ready = initializeNative\(root\);[\s\S]*?return this\.ready;/.test(harmonyEngine));
check('cleanup cannot throw through the environment hook and resets the attempt gate',
  /if \(gInitialized\)[\s\S]*?try \{[\s\S]*?tex::LaTeX::release\(\);[\s\S]*?catch \(\.\.\.\)/.test(cleanup) &&
  /gInitialized = false;[\s\S]*?gInitializationAttempted = false;[\s\S]*?gResourceRoot\.clear\(\)/.test(cleanup));

function initializationGate() {
  let attempted = false;
  let initialized = false;
  let rootPath = '';
  return {
    initialize(init) {
      if (!attempted) {
        attempted = true;
        try {
          const resolved = init();
          if (resolved.length > 0) {
            rootPath = resolved;
            initialized = true;
          }
        } catch (_error) {
          initialized = false;
          rootPath = '';
        }
      }
      return initialized;
    },
    cleanup() {
      attempted = false;
      initialized = false;
      rootPath = '';
    },
    state() { return { attempted, initialized, rootPath }; },
  };
}

check('runtime model caches a failed attempt and never invokes a poisoned retry', (() => {
  const gate = initializationGate();
  let calls = 0;
  const first = gate.initialize(() => { calls += 1; throw new Error('bad resources'); });
  const second = gate.initialize(() => { calls += 1; return '/repaired'; });
  return first === false && second === false && calls === 1 &&
    assert.deepEqual(gate.state(), { attempted: true, initialized: false, rootPath: '' }) === undefined;
})());
check('runtime model commits only a successful non-empty resource root', (() => {
  const empty = initializationGate();
  const valid = initializationGate();
  return empty.initialize(() => '') === false && valid.initialize(() => '/glmath/v1') === true &&
    assert.deepEqual(valid.state(),
      { attempted: true, initialized: true, rootPath: '/glmath/v1' }) === undefined;
})());
check('runtime model cleanup resets the gate for a new environment lifecycle', (() => {
  const gate = initializationGate();
  gate.initialize(() => { throw new Error('first lifecycle'); });
  gate.cleanup();
  return gate.initialize(() => '/glmath/v1') === true;
})());

console.log(`TOTAL=${checks.length} FAILED=0`);
