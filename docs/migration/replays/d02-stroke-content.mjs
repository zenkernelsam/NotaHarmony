// Phase 1183 — stroke-content taxonomy (3 kinds + ViewportState real names)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('mwd = BezierStrokeContent', R('mwd.java').includes('BezierStrokeContent'));
t('nwd = CentralPathStrokeContent', R('nwd.java').includes('CentralPathStrokeContent'));
t('owd = PencilStrokeContent', R('owd.java').includes('PencilStrokeContent'));
t('owd has splats', R('owd.java').includes('splats'));
t('all 3 extend pwd', R('mwd.java').includes('extends pwd') && R('nwd.java').includes('extends pwd') && R('owd.java').includes('extends pwd'));
t('mwd/nwd hold ife+t16', R('mwd.java').includes('ife') && R('nwd.java').includes('ife') && R('nwd.java').includes('t16'));
const t0g = R('t0g.java');
t('t0g = ViewportState', t0g.includes('ViewportState'));
t('t0g zoom + pageWidthRelativeZoom', t0g.includes('zoom=') && t0g.includes('pageWidthRelativeZoom'));
t('t0g functional+visible viewportRect', t0g.includes('functionalViewportRect') && t0g.includes('visibleViewportRect'));
t('t0g areTransformsTransient + density', t0g.includes('areTransformsTransient') && t0g.includes('density'));
console.log('stroke-content replay: ' + n + '/10 checks green');
