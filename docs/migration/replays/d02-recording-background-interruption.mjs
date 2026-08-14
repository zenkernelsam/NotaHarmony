import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

function read(relative) {
  return fs.readFileSync(path.join(root, relative), 'utf8');
}

const backend = read(
  'note/src/main/ets/core/adaptation/OriginalRecordingMicrophoneBackend.ets');
const session = read(
  'note/src/main/ets/core/adaptation/OriginalRecordingSessionController.ets');
const tests = read('note/src/test/OriginalRecordingSessionController.test.ets');
const originalState = fs.readFileSync(path.join(originalRoot, 'wr8.java'), 'utf8');
const originalStart = fs.readFileSync(path.join(originalRoot, 'tr8.java'), 'utf8');

const handlerRegistration = backend.indexOf("recorder.on('stateChange'");
const prepare = backend.indexOf('await recorder.prepare(config)');
const off = backend.indexOf("recorder.off('stateChange'");
const release = backend.indexOf('await recorder.release()');
const interruptionMethod = session.slice(session.indexOf('private onCaptureInterrupted()'),
  session.indexOf('private async deactivateFocus()'));

const checks = [
  ['original microphone capture turns audio focus loss into an interruption signal',
    /Audio focus lost, interrupting recording[\s\S]*wr8Var\.f\.f\(mof\.a\)/
      .test(originalState)],
  ['original recorder installs both information and error listeners',
    /setOnInfoListener\(wr8Var\.c\)[\s\S]*setOnErrorListener\(wr8Var\.d\)/
      .test(originalStart)],
  ['Harmony subscribes to AVRecorder state before prepare and start',
    handlerRegistration >= 0 && handlerRegistration < prepare],
  ['only system-background paused or stopped transitions interrupt capture',
    backend.includes('reason !== media.StateChangeReason.BACKGROUND') &&
      backend.includes("state !== 'paused' && state !== 'stopped'")],
  ['one recorder instance emits at most one interruption request',
    backend.includes('this.interruptionNotified = true') &&
      backend.includes('|| this.interruptionNotified')],
  ['already system-stopped output is finalized without an illegal second stop',
    /recorder\.state !== 'started' && recorder\.state !== 'paused' &&[\s\S]*recorder\.state !== 'stopped'/
      .test(backend) &&
      /if \(recorder\.state !== 'stopped'\) \{[\s\S]*await recorder\.stop\(\)/.test(backend)],
  ['state listener is detached before recorder release',
    off >= 0 && release >= 0 && off < release],
  ['backend and audio-focus interruptions share the serialized stop-and-save path',
    interruptionMethod.includes('this.stop().catch') &&
      !interruptionMethod.includes('this.focusActive = false') &&
      /const result:[\s\S]*await this\.capture\.stop\(\)[\s\S]*await this\.deactivateFocus\(\)/
        .test(session)],
  ['session tests require microphone backend interruption to release focus and persist',
    tests.includes('microphone backend is interrupted') &&
      tests.includes("'permission,before-start,focus-on,focus-off,persist'")],
];

for (const [name, ok] of checks) {
  assert.equal(ok, true, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

let notified = false;
function interruptionModel(state, reason) {
  if (reason !== 'background' || (state !== 'paused' && state !== 'stopped') || notified) {
    return false;
  }
  notified = true;
  return true;
}

assert.equal(interruptionModel('started', 'user'), false);
assert.equal(interruptionModel('paused', 'user'), false);
assert.equal(interruptionModel('started', 'background'), false);
assert.equal(interruptionModel('paused', 'background'), true);
assert.equal(interruptionModel('stopped', 'background'), false);
console.log('PASS: runtime policy ignores user transitions and deduplicates background interruption');

console.log(`TOTAL=${checks.length + 1} FAILED=0`);
