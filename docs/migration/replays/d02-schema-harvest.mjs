// Phase 1150 — w1b descriptor schema-name harvest
import { readFileSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const all = readdirSync(D).filter(f=>f.endsWith('.java')).map(f=>readFileSync(D+f,'utf8')).join('\n');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('schema: Rect', all.includes('flatbuffers/Rect'));
t('schema: Paper', all.includes('flatbuffers/Paper'));
t('schema: LayoutMode', all.includes('flatbuffers/LayoutMode'));
t('schema: InkStyle + InkTool', all.includes('flatbuffers/InkStyle') && all.includes('flatbuffers/InkTool'));
t('schema: TapePattern + TextWrapMode', all.includes('flatbuffers/TapePattern') && all.includes('flatbuffers/TextWrapMode'));
t('schema: PageBackground + BlockCornerType', all.includes('flatbuffers/PageBackground') && all.includes('flatbuffers/BlockCornerType'));
t('prop: cropRect + paper', all.includes('"cropRect"') && all.includes('"paper"'));
t('prop: imageFlipped*', all.includes('"imageFlippedVertically"') && all.includes('"imageFlippedHorizontally"'));
t('prop: defaultFont* + layoutMode', all.includes('"defaultFontFamily"') && all.includes('"defaultFontSize"') && all.includes('"layoutMode"'));
t('prop: members + background', all.includes('"members"') && all.includes('"background"'));
console.log('schema-harvest replay: ' + n + '/10 checks green');
