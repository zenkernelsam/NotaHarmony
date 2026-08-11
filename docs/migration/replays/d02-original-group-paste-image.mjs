import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const baj = original('baj.java');
const rl2 = original('rl2.java');
const iuh = original('iuh.java');
const encoder = read('note/src/main/ets/data/OriginalCreateBlockPayloadEncoder.ets');
const reducer = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const fixtures = read('note/src/test/OriginalCreateTextPayloadEncoder.test.ets');

assert.match(baj, /aVar\.h\(10, numValueOf\.intValue\(\)\)/);
assert.match(baj, /aVar\.j\(11, ldj\.A2\(bmbVar, aVar\)\)/);
assert.match(baj, /aVar\.h\(12, numValueOf3\.intValue\(\)\)/);
assert.match(baj, /aVar\.a\(17, z3, false\)/);
assert.match(baj, /aVar\.a\(16, z2, false\)/);
assert.match(baj, /aVar\.a\(20, z5, false\)/);
assert.match(rl2, /Must provide an assetType for an Image Block/);
assert.match(iuh, /aVarA\.C\(2\)/);
assert.match(iuh, /aVarA\.h\(0, iC\)/);
assert.match(iuh, /aVarA\.j\(1, apb\.Z\(qedVar, aVarA\)\)/);

assert.match(encoder, /encodeOriginalLocalCreateImageBlock/);
assert.match(encoder, /fields\[10\] = 52/);
assert.match(encoder, /fields\[11\] = image\.cropRect === null \? 0 : 56/);
assert.match(encoder, /fields\[12\] = webUrl === null \? 0 : 72/);
assert.match(encoder, /fields\[16\] = image\.imageFlippedHorizontally \? 76 : 0/);
assert.match(encoder, /fields\[17\] = image\.imageFlippedVertically \? 77 : 0/);
assert.match(encoder, /fields\[20\] = image\.positionLocked \? 78 : 0/);
assert.match(encoder, /writeHash\(bytes, metadataTable \+ 4, image\.assetHashBits\)/);
assert.match(fixtures, /round-trips original Image state through CREATE_BLOCK/);

assert.match(reducer, /mergeImageAssetReference\(/);
assert.match(reducer, /CREATE_BLOCK_IMAGE_ASSET_METADATA_CONFLICT/);
assert.match(reducer, /mergeNoteIds\(row\.noteIds, \[noteId\]\)/);
assert.match(persistence, /createdImages\.push\(materializeOriginalImageCreate/);
assert.match(persistence, /createdImages, createdMathBlocks/);
assert.match(persistence, /images: createdImages, mathBlocks: createdMathBlocks/);
assert.match(canvas, /this\.refreshImageAssets\(this\.pageLoadGeneration, pageId\)/);

function pasteImage({ failAt = '', conflict = false } = {}) {
  const initial = {
    revision: 8,
    operations: [],
    images: [],
    groups: [],
    history: [],
    asset: { status: 'LOCAL', localPath: '/assets/final/hash', noteIds: ['source'] },
  };
  const state = structuredClone(initial);
  try {
    if (conflict) throw new Error('metadata conflict');
    state.asset.noteIds.push('destination');
    if (failAt === 'ASSET_REFERENCE') throw new Error(failAt);
    state.operations.push('CREATE_IMAGE_BLOCK');
    state.images.push({ crop: [10, 20, 600, 440], flips: [true, true], locked: true });
    if (failAt === 'CREATE_IMAGE_BLOCK') throw new Error(failAt);
    state.revision++;
    state.operations.push('CREATE_GROUP');
    state.groups.push('top');
    if (failAt === 'CREATE_GROUP') throw new Error(failAt);
    state.history.push('NCP1');
    if (failAt === 'NCP1') throw new Error(failAt);
    return state;
  } catch {
    return initial;
  }
}

const committed = pasteImage();
assert.equal(committed.revision, 9);
assert.deepEqual(committed.operations, ['CREATE_IMAGE_BLOCK', 'CREATE_GROUP']);
assert.equal(committed.asset.status, 'LOCAL');
assert.equal(committed.asset.localPath, '/assets/final/hash');
assert.deepEqual(committed.asset.noteIds, ['source', 'destination']);
assert.deepEqual(committed.groups, ['top']);
assert.deepEqual(committed.history, ['NCP1']);
for (const failAt of ['ASSET_REFERENCE', 'CREATE_IMAGE_BLOCK', 'CREATE_GROUP', 'NCP1']) {
  assert.deepEqual(pasteImage({ failAt }), pasteImage({ conflict: true }));
}

console.log('originalGroupPasteImage=' +
  'type22-sha512-metadata-crop-url-flips-lock-asset-reference-canonical-ui-rollback');
