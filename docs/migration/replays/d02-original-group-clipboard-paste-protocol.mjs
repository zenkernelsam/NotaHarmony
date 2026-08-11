import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const lg2 = original('sources/defpackage/lg2.java');
const codec = read('note/src/main/ets/data/OriginalClipboardPasteMutationCodec.ets');
const singleGroupCodec = read('note/src/main/ets/data/OriginalGroupMutationOpCodec.ets');
const fixtures = read('note/src/test/OriginalClipboardPasteMutationCodec.test.ets');

assert.match(lg2, /c\(set, linkedHashSet2, linkedHashSet3, x09Var, arrayList3/);
assert.match(lg2, /u5j\.c\(x09Var, au1\.A1\(au1\.T1\(set\), arrayList3\)/);
assert.match(lg2, /\(\(uq9\) next\)\.m\(\) == haa\.CREATE_GROUP/);
assert.match(codec, /MAGIC: number\[\] = \[0x4E, 0x43, 0x50, 0x31\]/);
assert.match(codec, /classifyPageMutation\(mutation\.pageMutation\) !== OpType\.INSERT_ELEMENTS/);
assert.match(codec, /decodeOperationId\(element\.elementId\) === null/);
assert.match(codec, /!availableMembers\.has\(member\)/);
assert.match(codec, /parentByMember\.has\(member\)/);
assert.match(codec, /actualRoots\.size !== expectedRoots\.size/);
assert.match(codec, /entryCount > MAX_OPERATION_ELEMENTS/);
assert.match(codec, /size > MAX_OPERATION_BYTES/);
assert.match(singleGroupCodec, /MAX_GROUPS_PER_MUTATION: number = 1/);
assert.match(singleGroupCodec, /samePageElementMembers/);
assert.match(fixtures, /bottom-up nested Groups and exact top selection roots/);
assert.match(fixtures, /element\('op:17:2'/);
assert.match(fixtures, /rejects forward Group references duplicate parents and incorrect roots/);

function validate(inserted, groups, roots) {
  const available = new Set(inserted);
  const groupIds = new Set();
  const parent = new Map();
  for (const group of groups) {
    assert(!available.has(group.id));
    assert(!groupIds.has(group.id));
    for (const member of group.members) {
      assert(available.has(member), `future or foreign member ${member}`);
      assert(!parent.has(member), `duplicate parent for ${member}`);
      parent.set(member, group.id);
    }
    groupIds.add(group.id);
    available.add(group.id);
  }
  const expected = new Set([...groupIds].filter(id => !parent.has(id)));
  assert.deepEqual(new Set(roots), expected);
}

const inserted = ['op:14:2', 'op:15:2', 'op:16:2', 'op:17:2'];
const valid = [
  { id: 'op:1e:3', members: ['op:14:2', 'op:15:2'] },
  { id: 'op:1f:3', members: ['op:1e:3', 'op:16:2'] },
];
validate(inserted, valid, ['op:1f:3']);
assert.doesNotThrow(() => validate(inserted, valid, ['op:1f:3']));
assert.throws(() => validate(inserted, [
  { id: 'op:1e:3', members: ['op:1f:3'] },
  { id: 'op:1f:3', members: ['op:14:2'] },
], ['op:1e:3']), /future or foreign member/);
assert.throws(() => validate(inserted, [
  { id: 'op:1e:3', members: ['op:14:2'] },
  { id: 'op:1f:3', members: ['op:14:2'] },
], ['op:1e:3', 'op:1f:3']), /duplicate parent/);
assert.throws(() => validate(inserted, valid, ['op:1e:3']));

console.log('originalGroupClipboardPasteProtocol=' +
  'insert-only-canonical-bottom-up-tree-exact-roots-independent-leaves-budgeted');
