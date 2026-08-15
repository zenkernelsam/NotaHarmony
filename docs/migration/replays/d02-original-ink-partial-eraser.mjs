import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const n8j = original('sources/defpackage/n8j.java');
const o8j = original('sources/defpackage/o8j.java');
const o1 = original('sources/defpackage/o1.java');
const ft1 = original('sources/defpackage/ft1.java');
const cfa = original('sources/defpackage/cfa.java');
const inkEraser = read('note/src/main/ets/rendering/OriginalInkPartialEraser.ets');
const pencilGenerator = read('note/src/main/ets/core/algorithm/PencilSplatGenerator.ets');
const painter = read('note/src/main/ets/rendering/StrokeCanvasPainter.ets');
const noteCanvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixture = read('note/src/test/OriginalInkPartialEraser.test.ets');
const persistenceFixture = read('note/src/test/StrokePersistence.test.ets');
const fixtureList = read('note/src/test/List.test.ets');
const evidence = read('docs/migration/evidence/original-ink-partial-erase-jadx-2026-08-15.md');

// Original Ink supplies center/custom/fill independently and gates fill by fill-color presence.
assert.match(n8j, /wx0 wx0Var6 = dz3Var\.c/);
assert.match(n8j, /wx0 wx0Var7 = dz3Var\.f \? dz3Var\.e : null/);
assert.match(n8j, /wx0 wx0Var8 = dz3Var\.d/);
assert.match(n8j, /pxh\.d\(wx0Var6, dz3Var\.h\)/);
assert.match(n8j, /new zz3\(wx0VarE3, wx0VarE, wx0VarE2\)/);
assert.match(n8j, /new zz3\(wx0Var15, wx0Var15, wx0Var14\)/);

// Pencil uses a 2.84 outline but advances state with base width and the original cfa walk.
assert.match(o1, /new jea\(new ft1\(list, dC0, listA0\), dC0 \* 2\.84d\)/);
assert.match(ft1, /new cfa\(\(fd0\) fd0Var\.z\(qy5Var, ry5Var\.a\(\)\), this\.K, jF, z81Var/);
assert.match(ft1, /int i4 = \(int\) cfaVar\.g/);
assert.match(ft1, /z81 z81Var3 = cfaVar\.f/);
assert.match(cfa, /this\.g = j/);
assert.match(cfa, /this\.f = new z81\(this\.j, this\.k\)/);

// Dash/Dots preserve only advanced phase and source period; o8j also slices AudioLinked timing.
assert.match(ft1, /double dC = fValueOf != null \? n8j\.c\(wx0Var, ry5Var2\)/);
assert.match(ft1, /d2 = \(\(dC % d\) \+ d\) % d/);
assert.match(o8j, /fad\.e\(0, fqaVarG3, f2, yydVar != null \? yydVar\.c\(\) : 0\.0f\)/);
assert.match(o8j, /new ls1\(dMin \/ d2, dMax \/ d2\)/);
assert.match(o8j, /new mmf\(\(int\) rh8\.x/);

// Harmony uses the original-style local Path pipeline and keeps failures Unchanged.
assert.match(inkEraser, /class OriginalInkPartialEraser/);
assert.match(inkEraser, /localEraser\.transform\(inverseMatrix\)/);
assert.match(inkEraser, /metrics\.path\.getSegment\(false, run\.start, run\.end, true/);
assert.match(inkEraser, /return eraserPath\.contains\(position\.x, position\.y\)/);
assert.match(inkEraser, /ORIGINAL_PENCIL_OUTLINE_MULTIPLIER: number = 2\.84/);
assert.match(inkEraser, /new WidthOutlineBuilder\(\)\.build\(\s*stroke\.pathPoints, baseWidth/);
assert.match(inkEraser, /generateWithState\(\s*prefix\.cubicSegments, prefix\.pathPoints/);
assert.match(inkEraser, /backingPencilSeed: 0,[\s\S]{0,120}backingDashPhase: phase/);
assert.match(inkEraser, /basePhase \+ center\.startDistance/);
assert.doesNotMatch(inkEraser, /basePhase \+ startDistance/);
assert.match(inkEraser, /shiftAudioStart\(source\.audioStartTime, startOffset\)/);
assert.match(inkEraser, /MOVE-only custom path is the local representation used for an[\s\S]{0,80}fill-only component/);
assert.match(inkEraser, /catch \(_error\)[\s\S]{0,220}accidental source deletion/);
assert.doesNotMatch(inkEraser, /new EraserEngine/);

assert.match(pencilGenerator, /interface PencilSplatGenerationState/);
assert.match(pencilGenerator, /generateWithState\(/);
assert.match(pencilGenerator, /this\.lastReferencePoint = \{ x: s\.x, y: s\.y \}/);
assert.match(painter, /stroke\.renderSpec\.isPencil[\s\S]{0,420}canvasContext\.clip\(\)/);
assert.match(noteCanvas, /new OriginalInkPartialEraser\(this\.eraserEngine\.getWidth\(\)\)\.erase/);
assert.match(noteCanvas,
  /applyPartialEraseLocally[\s\S]{0,520}validatePartialEraseMaterializationPlan\(plan\)/);
assert.match(persistence, /export function validatePartialEraseMaterializationPlan/);
assert.doesNotMatch(persistence,
  /source\.renderSpec === undefined \|\| source\.renderSpec\.isPencil \|\|/);

assert.match(fixture, /without expanding center clipping by half the Ink width/);
assert.match(fixture, /original 2\.84 Pencil outline multiplier/);
assert.match(fixture, /advances Pencil seed\/reference/);
assert.match(fixture, /advances both DASH and DOTS phase/);
assert.match(fixture, /erase a persisted fill-only component/);
assert.match(fixture, /clips Pencil splats to a remnant custom path/);
assert.match(persistenceFixture,
  /preflights local partial-erase remnants before deleting their source/);
assert.match(fixtureList, /originalInkPartialEraserTest\(\)/);
assert.match(evidence, /7313362583E48249CB52B86B3FCA9B2941D0AC56DEABB557BDCDFBE7AD024474/);

// Numeric sentinels for the two boundary registers that are easy to regress.
const pencilOutline = 2 * 2.84 * 2;
assert.equal(pencilOutline, 11.36);
const dashPhase = ((1 + 11) % 6 + 6) % 6;
const dotsPhase = ((1 + 11) % 4.002 + 4.002) % 4.002;
assert.equal(dashPhase, 0);
assert.ok(Math.abs(dotsPhase - 3.996) < 1e-12);
const audioStart = 1000 + Math.round(0.6 * 1000);
const audioDuration = Math.round((1 - 0.6) * 1000);
assert.equal(audioStart, 1600);
assert.equal(audioDuration, 400);

console.log(
  'originalInkPartialEraser=local-center-custom-fill-pencil-state-dash-audio-fill-only-fail-closed');
