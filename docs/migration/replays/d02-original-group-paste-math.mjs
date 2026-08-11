import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const baj = original('baj.java');
const rl2 = original('rl2.java');
const encoder = read('note/src/main/ets/data/OriginalCreateBlockPayloadEncoder.ets');
const reducer = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const fixtures = read('note/src/test/OriginalCreateTextPayloadEncoder.test.ets');
const persistenceFixtures = read('note/src/test/StrokePersistence.test.ets');

assert.match(baj, /aVar\.C\(21\)/);
assert.match(baj, /aVar\.h\(13, numValueOf4\.intValue\(\)\)/);
assert.match(baj, /aVar\.j\(14, z5c\.P\(hu1Var, aVar\)\)/);
assert.match(baj, /aVar\.a\(20, z5, false\)/);
assert.match(rl2, /Must provide latex and color for a Math Block/);

assert.match(encoder, /encodeOriginalLocalCreateMathBlock/);
assert.match(encoder, /fields\[0\] = 4/);
assert.match(encoder, /fields\[13\] = 52/);
assert.match(encoder, /fields\[14\] = 56/);
assert.match(encoder, /fields\[20\] = math\.positionLocked \? 60 : 0/);
assert.match(encoder, /isRepresentableBlockTransform/);
assert.match(reducer, /payload\.blockType === OriginalBlockType\.MATH \? this\.buildMathBlock/);

assert.match(persistence, /plan\.mathBlocks\.length/);
assert.match(persistence, /encodeOriginalLocalCreateMathBlock\(page, math\)/);
assert.match(persistence, /original clipboard Math CREATE_BLOCK was deferred/);
assert.match(persistence, /materializeOriginalMathCreate\(identity\.opId, decoded\)/);
assert.match(persistence, /images: createdImages, mathBlocks: createdMathBlocks/);
assert.match(persistence, /encodeOriginalLocalCreateImageBlock\(page, image\)/);
assert.match(canvas, /this\.mathBlocks = this\.mathBlocks\.concat\(result\.mathBlocks\)/);
assert.match(canvas, /result\.mathBlocks\.map\(\(math: MathElement\)/);
assert.match(fixtures, /round-trips original Math state through CREATE_BLOCK/);
assert.match(persistenceFixtures, /mathBlocks: \[math\]/);

function pasteMath(failAt = '') {
  const initial = { revision: 8, operations: [], math: [], groups: [], history: [] };
  const state = structuredClone(initial);
  try {
    state.operations.push('CREATE_MATH_BLOCK');
    if (failAt === 'CREATE_MATH_BLOCK') throw new Error(failAt);
    state.math.push({ latex: '\\frac{a}{b}', color: 0x80112233, locked: true });
    if (failAt === 'FLUSH') throw new Error(failAt);
    state.revision++;
    state.operations.push('CREATE_GROUP');
    state.groups.push('top');
    if (failAt === 'NCP1') throw new Error(failAt);
    state.history.push('NCP1');
    return state;
  } catch {
    return initial;
  }
}

const committed = pasteMath();
assert.equal(committed.revision, 9);
assert.deepEqual(committed.operations, ['CREATE_MATH_BLOCK', 'CREATE_GROUP']);
assert.deepEqual(committed.math,
  [{ latex: '\\frac{a}{b}', color: 0x80112233, locked: true }]);
assert.deepEqual(committed.groups, ['top']);
assert.deepEqual(committed.history, ['NCP1']);
for (const stage of ['CREATE_MATH_BLOCK', 'FLUSH', 'NCP1']) {
  assert.deepEqual(pasteMath(stage),
    { revision: 8, operations: [], math: [], groups: [], history: [] });
}

console.log('originalGroupPasteMath=' +
  'type22-latex-color-transform-lock-single-revision-group-ncp1-canonical-ui-rollback');
