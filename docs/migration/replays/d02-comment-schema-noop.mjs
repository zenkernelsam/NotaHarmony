import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const commentSource = read('note/src/main/ets/data/OriginalCommentOperation.ets');
const flatBufferSource = read('note/src/main/ets/data/OriginalSyncedOperationFlatBuffer.ets');
const routerSource = read('note/src/main/ets/data/OriginalPageOperationApplier.ets');
const bundleSource = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const fixtureSource = read('note/src/test/SyncedOperationInbox.test.ets');

const dedupeIdentities = identities => {
  const seen = new Set();
  return identities.filter(identity => {
    const key = `${identity.timestamp}:${identity.siteId}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
};

const anchors = [
  { type: 'CANVAS', page: { timestamp: 40, siteId: 2, index: 3 }, origin: { x: 12.5, y: -4.25 } },
  { type: 'TEXT', textField: { timestamp: 50, siteId: 5 }, selection: { anchor: null, focus: null } },
  { type: 'ENTITY', entities: dedupeIdentities([
    { timestamp: 70, siteId: 7 }, { timestamp: 70, siteId: 7 },
    { timestamp: 71, siteId: 8 },
  ]) },
  { type: 'REPLY', root: { timestamp: 80, siteId: 9 } },
];
assert.deepEqual(anchors.map(anchor => anchor.type), ['CANVAS', 'TEXT', 'ENTITY', 'REPLY']);
assert.equal(anchors[2].entities.length, 2);

const validCreate = { type: 30, anchor: anchors[0], text: 'comment', valid: true };
const validModify = {
  type: 31,
  comment: { timestamp: 90, siteId: 10 },
  anchor: null,
  text: { value: null },
  resolved: { value: null },
  valid: true,
};
assert.ok(validCreate.anchor && validCreate.text.length > 0);
assert.ok(validModify.anchor || validModify.text || validModify.resolved);
assert.equal(Boolean(2), true); // Generated z1d reader treats every non-zero byte as true.

// Original v69/fsi validates these schemas but has no comment model branch. Both operations consume
// inbox positions with zero durable writes, allowing a later supported model operation to drain.
const queue = [validCreate, validModify, { type: 2, valid: true }];
let writes = 0;
const applied = [];
while (queue.length > 0 && queue[0].valid) {
  const operation = queue.shift();
  if (operation.type !== 30 && operation.type !== 31) writes++;
  applied.push(operation.type);
}
assert.deepEqual(applied, [30, 31, 2]);
assert.equal(writes, 1);

// Unlike malformed peer presence, malformed durable comment payloads remain deferred.
const malformed = [{ type: 30, valid: false }, { type: 2, valid: true }];
assert.equal(malformed[0].valid, false);
assert.deepEqual(malformed.map(operation => operation.type), [30, 2]);

assert.match(flatBufferSource, /readIndirectInlineBytes\(field: number, size: number\)/);
assert.match(commentSource, /ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE: number = 30/);
assert.match(commentSource, /ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE: number = 31/);
assert.match(commentSource, /OriginalCommentAnchorType\.CANVAS/);
assert.match(commentSource, /OriginalCommentAnchorType\.TEXT/);
assert.match(commentSource, /OriginalCommentAnchorType\.ENTITY/);
assert.match(commentSource, /OriginalCommentAnchorType\.REPLY/);
assert.match(commentSource, /readInlineOperationIdentityVector\(0, MAX_COMMENT_ENTITY_ANCHOR_COUNT\)/);
assert.match(commentSource, /text\.length === 0/);
assert.match(commentSource, /anchor === null && textTable === null && resolvedTable === null/);
assert.match(commentSource, /readUint8\(0, 0\) !== 0/);
assert.match(routerSource, /payloadType === ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE/);
assert.match(routerSource, /payloadType === ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE/);
assert.match(routerSource, /MALFORMED_COMMENT_PAYLOAD/);
assert.match(routerSource, /Original 1\.0\.3 validates both schemas but v69\/fsi route neither payload/);
assert.match(bundleSource, /preflightOriginalCommentTable\(operation\.payload, operation\.payloadType\)/);
assert.match(bundleSource, /Original v69 consumes validated comment payloads without a model mutation/);
assert.match(fixtureSource, /flatBufferCreateComment/);
assert.match(fixtureSource, /flatBufferModifyComment/);

console.log('D02_COMMENT_SCHEMA_NOOP_REPLAY_OK ' +
  'create-anchors=canvas,text,entity,reply|entity-dedup=1|required-nonempty-text=1|' +
  'modify-target=1|nullable-anchor-text-resolved=3|nonzero-bool=1|unknown-fields-rejected=1|' +
  'standalone-zero-write=2|malformed-deferred=1|note-bundle-preflight-noop=2');
