// Phase 1158 — n5d/ry0 full property maps + new schema names
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const n5d = R('n5d'), ry0 = R('ry0');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('n5d rotation+scale props', n5d.includes('"rotation"') && n5d.includes('"scale"'));
t('n5d definition→ShapeDefinition (named pkg)', n5d.includes('"definition"') && n5d.includes('entities/ShapeDefinition'));
t('n5d tool→InkTool + style→InkStyle', n5d.includes('"tool"') && n5d.includes('flatbuffers/InkTool') && n5d.includes('flatbuffers/InkStyle'));
t('n5d tapePattern→TapePattern', n5d.includes('"tapePattern"') && n5d.includes('flatbuffers/TapePattern'));
t('n5d color+borderWidth+fillColor', n5d.includes('"color"') && n5d.includes('"borderWidth"') && n5d.includes('"fillColor"'));
t('n5d zIndex-tJoBMIg + positionLocked', n5d.includes('"zIndex"') && n5d.includes('"positionLocked"'));
t('ry0 size+scale props', ry0.includes('"size"') && ry0.includes('"scale"'));
t('ry0 corner→BlockCornerType', ry0.includes('"corner"') && ry0.includes('flatbuffers/BlockCornerType'));
t('ry0 textWrap→TextWrapMode', ry0.includes('"textWrap"') && ry0.includes('flatbuffers/TextWrapMode'));
t('ry0 enableCaption + zIndex', ry0.includes('"enableCaption"') && ry0.includes('"zIndex"'));
console.log('entity-props replay: ' + n + '/10 checks green');
