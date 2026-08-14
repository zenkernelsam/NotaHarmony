import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const originalEngine = original('s18.java');
const originalDraw = original('p18.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const readStringStart = native.indexOf('bool ReadString(');
const readDoubleStart = native.indexOf('\nbool ReadDouble(', readStringStart);
const readString = native.slice(readStringStart, readDoubleStart);
const settersStart = native.indexOf('bool SetNumber(');
const parseStart = native.indexOf('\nstd::unique_ptr<tex::TeXRender> Parse(', settersStart);
const setters = native.slice(settersStart, parseStart);
const initializeStart = native.indexOf('napi_value Initialize(');
const measureStart = native.indexOf('\nnapi_value Measure(', initializeStart);
const renderStart = native.indexOf('\nnapi_value Render(', measureStart);
const cleanupStart = native.indexOf('\nvoid Cleanup(', renderStart);
const moduleStart = native.indexOf('napi_value Init(', cleanupStart);
const initialize = native.slice(initializeStart, measureStart);
const measure = native.slice(measureStart, renderStart);
const render = native.slice(renderStart, cleanupStart);
const moduleInit = native.slice(moduleStart, native.indexOf('\n} // namespace', moduleStart));

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original measurement caller treats a null native result as formula failure',
  /nativeMeasure\(str, f, fMax\)\) == null/.test(originalEngine) &&
  /nativeMeasure\(str, 100000\.0f, f\)\) == null/.test(originalEngine));
check('original draw caller recycles the bitmap when native drawing reports failure',
  /if \(GLMathNative\.a\.nativeDraw[\s\S]*?return bitmapCreateBitmap;[\s\S]*?bitmapCreateBitmap\.recycle\(\)/
    .test(originalDraw));

check('string input allocation is contained inside the native callback boundary',
  /try \{[\s\S]*?result\.resize\(length \+ 1\)[\s\S]*?catch \(\.\.\.\)[\s\S]*?result\.clear\(\);[\s\S]*?return false;/.test(readString));
check('all named-property helpers return status and initialize their N-API values',
  /bool SetNumber\(/.test(setters) && /napi_value number = nullptr;/.test(setters) &&
  /bool SetBoolean\(/.test(setters) && /napi_value boolean = nullptr;/.test(setters) &&
  /bool SetString\(/.test(setters) && /napi_value string = nullptr;/.test(setters));
check('all named-property helpers require value creation and property assignment success',
  /napi_create_double[\s\S]*?napi_set_named_property/.test(setters) &&
  /napi_get_boolean[\s\S]*?napi_set_named_property/.test(setters) &&
  /napi_create_string_utf8[\s\S]*?napi_set_named_property/.test(setters) &&
  (setters.match(/napi_set_named_property\(env, object, name,/g) ?? []).length === 3);
check('error results fail closed if object or either required field cannot be constructed',
  /napi_value ErrorResult[\s\S]*?napi_value result = nullptr;[\s\S]*?napi_create_object[\s\S]*?result == nullptr[\s\S]*?!SetBoolean[\s\S]*?!SetString[\s\S]*?return nullptr;/.test(setters));

check('every public callback checks napi_get_cb_info before reading arguments',
  /napi_get_cb_info[\s\S]*?!= napi_ok\) return nullptr;/.test(initialize) &&
  /napi_get_cb_info[\s\S]*?!= napi_ok\) return nullptr;/.test(measure) &&
  /napi_get_cb_info[\s\S]*?!= napi_ok\) return nullptr;/.test(render));
check('initialization checks boolean result creation rather than returning an uninitialized handle',
  /napi_value result = nullptr;[\s\S]*?napi_get_boolean\(env, gInitialized, &result\) != napi_ok/.test(initialize));
check('measure success checks the result object and all six required fields',
  /napi_create_object\(env, &result\) != napi_ok \|\| result == nullptr/.test(measure) &&
  /!SetBoolean\(env, result, "valid", true\)/.test(measure) &&
  /!SetNumber\(env, result, "width"/.test(measure) &&
  /!SetNumber\(env, result, "height"/.test(measure) &&
  /!SetNumber\(env, result, "baseline"/.test(measure) &&
  /!SetNumber\(env, result, "depth"/.test(measure));
check('render validates ArrayBuffer allocation before copying pixels',
  /napi_value pixels = nullptr/.test(render) &&
  /napi_create_arraybuffer[\s\S]*?!= napi_ok \|\|[\s\S]*?destination == nullptr \|\| pixels == nullptr/.test(render) &&
  render.indexOf('destination == nullptr') < render.indexOf('std::memcpy(destination, source, byteLength)'));
check('render success checks the result object scalar fields and pixels property',
  /napi_create_object\(env, &result\) != napi_ok \|\| result == nullptr/.test(render) &&
  /!SetBoolean\(env, result, "valid", true\)/.test(render) &&
  /!SetNumber\(env, result, "width", pixelWidth\)/.test(render) &&
  /!SetNumber\(env, result, "height", pixelHeight\)/.test(render) &&
  /napi_set_named_property\(env, result, "pixels", pixels\) != napi_ok/.test(render));
check('failed success-result construction returns through scoped native owners',
  render.indexOf('BitmapHandle bitmap(') < render.indexOf('napi_create_object(env, &result)') &&
  /napi_create_object[\s\S]*?return nullptr;/.test(render));
check('module export and cleanup-hook registration statuses are both checked',
  /napi_define_properties[\s\S]*?!= napi_ok \|\|[\s\S]*?napi_add_env_cleanup_hook[\s\S]*?!= napi_ok[\s\S]*?return nullptr;/.test(moduleInit));
check('native math no longer declares an uninitialized result value',
  !/napi_value result;/.test(native));

function constructResult(createObject, settersToRun) {
  const result = createObject();
  if (result === null) return null;
  for (const setter of settersToRun) {
    if (!setter(result)) return null;
  }
  return result;
}

check('runtime model never invokes field setters after object allocation failure', (() => {
  let setterCalls = 0;
  const result = constructResult(() => null, [() => { setterCalls += 1; return true; }]);
  return result === null && setterCalls === 0;
})());
check('runtime model short-circuits after the first failed property write', (() => {
  const calls = [];
  const result = constructResult(() => ({}), [
    () => { calls.push('valid'); return true; },
    () => { calls.push('width'); return false; },
    () => { calls.push('height'); return true; },
  ]);
  return result === null && assert.deepEqual(calls, ['valid', 'width']) === undefined;
})());

console.log(`TOTAL=${checks.length} FAILED=0`);
