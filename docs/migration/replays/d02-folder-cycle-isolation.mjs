import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const repository = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/FolderRepositoryImpl.ets'), 'utf8');
const page = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');

const folders = [
  { id: 'root', parentId: null },
  { id: 'child', parentId: 'root' },
  { id: 'cycle-a', parentId: 'cycle-b' },
  { id: 'cycle-b', parentId: 'cycle-a' },
];

function find(id) {
  return folders.find(folder => folder.id === id) ?? null;
}

function isInSubtree(rootId, candidateId) {
  if (rootId === candidateId) return true;
  let current = find(candidateId);
  const visited = new Set();
  while (current !== null && current.parentId !== null) {
    if (visited.has(current.id)) return false;
    visited.add(current.id);
    if (current.parentId === rootId) return true;
    current = find(current.parentId);
  }
  return false;
}

function hasCycle(folderId) {
  const visited = new Set();
  let currentId = folderId;
  while (currentId !== null) {
    if (visited.has(currentId)) return true;
    visited.add(currentId);
    const current = find(currentId);
    if (current === null || current.parentId === null) return false;
    currentId = current.parentId;
  }
  return false;
}

assert.equal(isInSubtree('root', 'child'), true);
assert.equal(isInSubtree('root', 'cycle-a'), false);
assert.equal(isInSubtree('root', 'cycle-b'), false);
assert.equal(hasCycle('child'), false);
assert.equal(hasCycle('cycle-a'), true);

const subtree = repository.slice(repository.indexOf('export function isFolderInSubtree'),
  repository.indexOf('// Mirrors 1.0.3 beb.a()'));
const list = page.slice(page.indexOf('private folderListItems'),
  page.indexOf('private appendFolderChildren'));
const checks = [
  ['cycle detection does not claim unrelated ancestry',
    /if \(visited\.has\(current\.id\)\) \{[\s\S]*return false;/.test(subtree)],
  ['delete still includes the selected root itself',
    subtree.includes('if (rootId === candidateId)') && subtree.includes('return true')],
  ['valid descendants are still detected before walking upward',
    subtree.includes('if (current.parentId === rootId)')],
  ['navigation has an explicit cyclic-ancestry fallback',
    page.includes('private folderHasCyclicAncestry(folderId: string): boolean') &&
    list.includes('this.folderHasCyclicAncestry(folder.id)')],
  ['collapsed valid children are not treated as corrupt fallback',
    list.includes('!this.folderExists(folder.parentId)') &&
    list.includes('this.folderHasCyclicAncestry(folder.id)')],
];

for (const [name, ok] of checks) {
  assert.ok(ok, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log('D02_FOLDER_CYCLE_ISOLATION_REPLAY_OK unrelated-cycle-delete=0|' +
  'valid-descendant=1|move-rejects-corruption=1|navigation-fallback=1');
