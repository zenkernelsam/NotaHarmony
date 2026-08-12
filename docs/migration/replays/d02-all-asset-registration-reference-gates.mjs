import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const block = fs.readFileSync(path.join(root, 'note/src/main/ets/data/OriginalCreateBlockOperation.ets'), 'utf8');
const recording = fs.readFileSync(path.join(root, 'note/src/main/ets/data/OriginalRecordingPersistence.ets'), 'utf8');
const checks = [
  ['CREATE_BLOCK imports shared validator', block.includes('validateNoteReferences }')],
  ['CREATE_BLOCK validates note identity', block.includes('validateNoteReferences(store, [noteId])')],
  ['CREATE_BLOCK validates merged IDs', block.includes('validateNoteReferences(store, mergedIds)')],
  ['recording imports shared validator', recording.includes('validateNoteReferences,')],
  ['recording validates merged IDs', recording.includes('await validateNoteReferences(store, noteIds)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
