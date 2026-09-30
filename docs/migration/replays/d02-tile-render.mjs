// Phase 1180 — tile render model (h0f ContentInputs + pwd/mwd drawables)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const h0f = R('h0f.java');
t('h0f ContentInputs name', h0f.includes('ContentInputs'));
t('h0f noteGeneration', h0f.includes('noteGeneration'));
t('h0f zoom', h0f.includes(', zoom='));
t('h0f tileWidth+tileHeight', h0f.includes('tileWidth') && h0f.includes('tileHeight'));
t('h0f useBezier', h0f.includes('useBezier'));
t('h0f showTileBorder', h0f.includes('showTileBorder'));
t('h0f selection+erase+pdfText', h0f.includes('idsToErase') && h0f.includes('selectionState') && h0f.includes('pdfTextSelectionState'));
const pwd = R('pwd.java');
t('pwd abstract drawable', pwd.includes('abstract class pwd') && pwd.includes('abstract Float a()'));
t('pwd Path+BlendMode', pwd.includes('Path') && pwd.includes('BlendMode'));
t('mwd extends pwd stroke drawable', R('mwd.java').includes('extends pwd'));
console.log('tile-render replay: ' + n + '/10 checks green');
