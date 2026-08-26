import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const callStart = page.indexOf('        RecordingPanel({');
const callEnd = page.indexOf('\n      }\n\n      // 画布', callStart);
assert.ok(callStart >= 0 && callEnd > callStart);
const call = page.slice(callStart, callEnd);

const closeStart = call.indexOf('          onClose: () => {');
const closeEnd = call.indexOf('\n          },', closeStart);
assert.ok(closeStart >= 0 && closeEnd > closeStart);
const closeCallback = call.slice(closeStart, closeEnd);
assert.match(closeCallback,
  /if \(this\.photoImportLeaseActive \|\| this\.pageStructureLeaseActive\) \{\s+return;\s+\}\s+this\.closeRecordings\(\);/);

assert.match(page, /private closeRecordings\(\): void \{\s+this\.showRecordings = false;\s+\}/);
assert.match(call, /photoImportLeaseActive: this\.photoImportLeaseActive,/);

console.log(
  'D02_RECORDING_CLOSE_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
