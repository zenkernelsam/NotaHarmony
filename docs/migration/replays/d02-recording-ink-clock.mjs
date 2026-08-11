import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const originalClock = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/vcj.java', 'utf8');
const originalRecorder = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/wr8.java', 'utf8');
const originalInk = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/kt1.java', 'utf8');
const originalCreateInk = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/u5j.java', 'utf8');
const capture = read('note/src/main/ets/core/adaptation/OriginalRecordingCaptureController.ets');
const session = read('note/src/main/ets/core/adaptation/OriginalRecordingSessionController.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const strokeSession = read('note/src/main/ets/rendering/StrokeSession.ets');
const captureTests = read('note/src/test/OriginalRecordingCaptureController.test.ets');
const strokeTests = read('note/src/test/StrokePrediction.test.ets');

assert.match(originalClock,
  /asdVar2\.getValue\(\)[\s\S]*!\(\(Boolean\) asdVar3\.getValue\(\)\)\.booleanValue\(\)/);
assert.match(originalClock, /new xgb\(wr8Var\.e\(\) \+ wr8Var\.j\)/);
assert.match(originalRecorder,
  /g3j\.b\(SystemClock\.elapsedRealtime\(\), this\.k, this\.l, this\.m/);
assert.match(originalInk, /vcj\.b\(this\.g, "ink\.create"\)/);
assert.match(originalInk, /new bt1\(this, dm2VarG, xgbVarB/);
assert.match(originalCreateInk, /xgb xgbVar, mmf mmfVar/);
assert.match(originalInk,
  /u5j\.g\(x09VarA,[\s\S]*?null, null, null, \(23564 & 8192\)[\s\S]*?null, null,/);

assert.match(capture, /getCurrentAudioTime\(\): string \| null/);
assert.match(capture, /this\.startWallTime \+ this\.currentElapsedMs\(\)/);
assert.match(capture, /this\.pausedAtUptime > 0/);
assert.match(session, /return this\.released \? null : this\.capture\.getCurrentAudioTime\(\)/);
assert.match(page, /readRecordingAudioTime:[\s\S]*session\.getCurrentAudioTime\(\)/);
assert.match(canvas,
  /beginStroke\([\s\S]*this\.viewport\.zoom, this\.readRecordingAudioTime\(\)\)/);
assert.match(strokeSession, /private audioStartTime: string \| null = null/);
assert.match(strokeSession, /audioStartTime: this\.audioStartTime === null \? undefined/);
assert.doesNotMatch(strokeSession, /audioDuration:/);
assert.match(captureTests, /getCurrentAudioTime\(\)\)\.assertNull\(\)/);
assert.match(strokeTests, /without inventing a duration/);

console.log('recordingInkClock=touch-down-active-unpaused-no-fake-duration');
