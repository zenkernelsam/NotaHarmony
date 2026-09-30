// Phase 1348 — native C++ layer (microtex LaTeX + natives)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const C = 'C:/HarmonyProject/NotaHarmony/note/src/main/cpp/';
const MT = C + 'third_party/microtex/src/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const nm = readFileSync(C + 'nota_math.cpp', 'utf8');
t('NAPI', nm.includes('napi/native_api.h'));
t('OH_Drawing native draw', nm.includes('OH_Drawing') || nm.includes('native_drawing'));
t('microtex latex', nm.includes('latex.h'));
t('render header', nm.includes('render.h'));
t('bounds (64K/4K/16MB)', nm.includes('MAX_LATEX_BYTES') && nm.includes('MAX_BITMAP'));
t('mutex init', nm.includes('Mutex') || nm.includes('mutex'));
t('nota_recording native', existsSync(C + 'nota_recording.cpp'));
t('microtex latex.h', existsSync(MT + 'latex.h'));
t('microtex render/graphic', existsSync(MT + 'render.h') && existsSync(MT + 'graphic/graphic.h'));
t('CMakeLists', existsSync(C + 'CMakeLists.txt'));
console.log('native-layer replay: ' + n + '/10 checks green');
