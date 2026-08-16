import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

const repository = read('note/src/main/ets/data/FolderRepositoryImpl.ets');
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const fixture = read('note/src/test/FolderRepository.test.ets');
const baseStrings = JSON.parse(read('note/src/main/resources/base/element/string.json'));
const zhStrings = JSON.parse(read('note/src/main/resources/zh_CN/element/string.json'));
const xdb = fs.readFileSync(path.join(originalRoot, 'xdb.java'), 'utf8');
const cm3 = fs.readFileSync(path.join(originalRoot, 'cm3.java'), 'utf8');
const gsi = fs.readFileSync(path.join(originalRoot, 'gsi.java'), 'utf8');
const im3 = fs.readFileSync(path.join(originalRoot, 'im3.java'), 'utf8');

const folder = (id, parentId, order, createdAt = order) =>
  ({ id, name: id, parentId, siblingOrder: order, createdAt });
const sameParent = (left, right) => left === right;
const find = (folders, id) => folders.find(candidate => candidate.id === id) ?? null;
const orderedSiblings = (folders, parentId, excludedId) => folders
  .filter(candidate => sameParent(candidate.parentId, parentId) && candidate.id !== excludedId)
  .sort((left, right) => left.siblingOrder - right.siblingOrder ||
    left.createdAt - right.createdAt || left.id.localeCompare(right.id));
const inSubtree = (folders, rootId, candidateId) => {
  if (rootId === candidateId) return true;
  let current = find(folders, candidateId);
  const visited = new Set();
  while (current !== null && current.parentId !== null) {
    if (visited.has(current.id)) return false;
    visited.add(current.id);
    if (current.parentId === rootId) return true;
    current = find(folders, current.parentId);
  }
  return false;
};

function planMove(folders, folderId, parentId, requestedIndex) {
  const siblings = orderedSiblings(folders, parentId, folderId);
  const insertIndex = Math.max(0, Math.min(Math.floor(requestedIndex), siblings.length));
  const ids = siblings.map(item => item.id);
  ids.splice(insertIndex, 0, folderId);
  return { parentId, insertIndex, ids };
}

function resolveDrop(folders, ids, depths, sourceIndex, rawInsertIndex, requestedDepth) {
  const sourceId = ids[sourceIndex];
  const boundary0 = Math.max(0, Math.min(Math.floor(rawInsertIndex), ids.length));
  const remainingIds = [];
  const remainingDepths = [];
  let removedBefore = 0;
  for (let index = 0; index < ids.length; index++) {
    if (inSubtree(folders, sourceId, ids[index])) {
      if (index < boundary0) removedBefore++;
    } else {
      remainingIds.push(ids[index]);
      remainingDepths.push(depths[index]);
    }
  }
  const boundary = Math.max(0, Math.min(boundary0 - removedBefore, remainingIds.length));
  let depth = Math.max(0, Math.floor(requestedDepth));
  depth = Math.min(depth, boundary === 0 ? 0 : remainingDepths[boundary - 1] + 1);
  let parentId = null;
  while (depth > 0) {
    for (let index = boundary - 1; index >= 0; index--) {
      if (remainingDepths[index] === depth - 1) {
        parentId = remainingIds[index];
        break;
      }
    }
    if (parentId !== null) break;
    depth--;
  }
  let childIndex = 0;
  for (let index = 0; index < boundary; index++) {
    const candidate = find(folders, remainingIds[index]);
    if (remainingDepths[index] === depth && candidate?.parentId === parentId) childIndex++;
  }
  return { folderId: sourceId, ...planMove(folders, sourceId, parentId, childIndex) };
}

const folders = [
  folder('a', null, 0), folder('a-child', 'a', 0),
  folder('b', null, 1), folder('c', null, 2),
];
const ids = ['a', 'a-child', 'b', 'c'];
const depths = [0, 1, 0, 0];
assert.deepEqual(resolveDrop(folders, ids, depths, 3, 0, 0).ids,
  ['c', 'a', 'b']);
assert.deepEqual(resolveDrop(folders, ids, depths, 0, 4, 0).ids,
  ['b', 'c', 'a']);
assert.equal(resolveDrop(folders, ids, depths, 2, 1, 0).parentId, null);
assert.equal(resolveDrop(folders, ids, depths, 2, 1, 0).insertIndex, 1);
assert.equal(resolveDrop(folders, ids, depths, 2, 1, 1).parentId, 'a');
assert.equal(resolveDrop(folders, ids, depths, 2, 1, 1).insertIndex, 0);
const empty = [folder('empty', null, 0), folder('move', null, 1)];
assert.equal(resolveDrop(empty, ['empty', 'move'], [0, 0], 1, 1, 1).parentId, 'empty');
const linear = [
  folder('linear-a', null, 0), folder('linear-b', null, 1),
  folder('linear-c', null, 2), folder('linear-d', null, 3),
];
assert.equal(resolveDrop(linear,
  ['linear-a', 'linear-b', 'linear-c', 'linear-d'], [0, 0, 0, 0], 1, 3, 0).insertIndex, 2);
assert.equal(resolveDrop(linear,
  ['linear-a', 'linear-b', 'linear-c', 'linear-d'], [0, 0, 0, 0], 1, 4, 0).insertIndex, 3);

// Original 1.0.3 stores parentId + childIndex and derives a fractional position from neighbours.
assert.match(cm3, /DragFolderResult\(folderId=.*parentId=.*childIndex=/);
assert.match(xdb, /this\.N/);
assert.match(xdb, /get\(i\)\)\.h\(\) - 1\.0d/);
assert.match(xdb, /get\(i - 1\)\)\.h\(\) \+ 1\.0d/);
assert.match(xdb, /get\(i - 1\)\)\.h\(\).*get\(i\)\)\.h\(\).*\/ 2\.0d/s);
assert.match(gsi, /j0\(48\.0f\)/);
assert.match(gsi, /j0\(24\.0f\)/);
assert.match(gsi, /new im3\(d27Var, fJ0, fJ1\)/);
assert.match(im3, /DragFolderResult|new cm3|em3Var\.b/);

// Harmony keeps the original contract while adapting storage to contiguous child indexes.
assert.match(repository, /ORIGINAL_FOLDER_DRAG_INDENT: number = 24/);
assert.match(repository, /planFolderMove\(folders: NoteFolder\[\], folderId: string/);
assert.match(repository, /newSiblingIds\.splice\(insertIndex, 0, folderId\)/);
assert.match(repository, /writeSiblingSequence\(store, plan\.oldSiblingIds\)/);
assert.match(repository, /writeSiblingSequence\(store, plan\.newSiblingIds\)/);
assert.match(repository, /visibleFolderDepths: number\[\]/);
assert.match(repository, /index < clampedBoundary/);
assert.match(repository, /clampedBoundary - removedBeforeBoundary/);
assert.match(repository, /remainingDepths\[boundary - 1\] \+ 1/);
assert.match(repository, /remainingDepths\[index\] === depth - 1/);
assert.match(page, /folderDragDepthAnchorX/);
assert.match(page, /event\.x - sourceDepth \* ORIGINAL_FOLDER_DRAG_INDENT/);
assert.match(page, /Math\.floor\(\(event\.x - this\.folderDragDepthAnchorX\) \/ ORIGINAL_FOLDER_DRAG_INDENT\)/);
assert.match(page, /item\.depth \* ORIGINAL_FOLDER_DRAG_INDENT/);
assert.match(page, /FolderDragPreview\(\)/);
assert.match(page, /return this\.FolderDragPreview/);
assert.match(page, /aboutToDisappear\(\): void \{[\s\S]*?this\.clearFolderDrag\(\)/);
assert.match(page, /\.onItemDragStart\(/);
assert.match(page, /\.onItemDrop\(/);
assert.match(page, /move_folder_up/);
assert.match(page, /move_folder_down/);
assert.match(fixture, /maps a flat drag boundary to the original destination parent and child index/);
assert.match(fixture, /intoEmptyParent/);

const resourceNames = value => new Set((value.string ?? value).map(item => item.name));
for (const name of ['move_folder_up', 'move_folder_down']) {
  assert.ok(resourceNames(baseStrings).has(name));
  assert.ok(resourceNames(zhStrings).has(name));
}

console.log('D02_ORIGINAL_FOLDER_INDEXED_DRAG_REPLAY_OK ' +
  'parent-child-index=1|before-middle-after=1|arkui-pre-removal-boundary=1|subtree-unit=1|' +
  'horizontal-depth-24dp=1|drag-preview-builder=1|' +
  'empty-parent=1|contiguous-transaction=1|fallback-actions=1');
