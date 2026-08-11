import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const originalModel = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/hkb.java', 'utf8');
const originalUi = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/n05.java', 'utf8');
const originalStrings = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const presentation = read('note/src/main/ets/core/adaptation/OriginalRecordingPresentation.ets');
const panel = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
const strings = read('note/src/main/resources/base/element/string.json');
const tests = read('note/src/test/OriginalRecordingPresentation.test.ets');

assert.match(originalModel, /this\.b = i/);
assert.match(originalModel, /if \(yjbVar\.L\(\)\.isEmpty\(\)\)/);
assert.match(originalModel, /this\.j = yjbVar\.N\(\)[\s\S]*this\.e = bdj\.b\(yjbVar\)/);
assert.match(originalModel, /ukbVar = \(ukb\) au1\.c1\(yjbVar\.L\(\)\)/);
assert.match(originalModel, /this\.j = ukbVar\.d\(\)[\s\S]*this\.e = ukbVar\.c\(\) - ukbVar\.d\(\)/);
assert.match(originalUi, /%01dh %01dm %01ds/);
assert.match(originalUi, /%01dm %01ds/);
assert.match(originalUi, /%01ds/);
assert.match(originalUi, /DateFormat\.getDateInstance\(2, Locale\.getDefault\(\)\)/);
assert.match(originalUi, /DateFormat\.getTimeInstance\(3, Locale\.getDefault\(\)\)/);
assert.match(originalStrings, /record_recording_user_facing_name">Recording %1\$s/);
assert.match(originalStrings, /recording_subtitle">%1\$s %2\$s, %3\$s/);

assert.match(presentation, /recording\.segments\[0\]\.startTime : recording\.startTime/);
assert.match(presentation, /originalRecordingEffectiveDurationMs\(recording\)/);
assert.match(presentation, /return `\$\{hours\}h \$\{minutes % 60\}m \$\{seconds\}s`/);
assert.match(presentation, /return `\$\{minutes\}m \$\{seconds\}s`/);
assert.match(presentation, /return `\$\{seconds\}s`/);
assert.match(panel, /recording_user_facing_name', index \+ 1/);
assert.match(panel, /dateStyle: 'medium'/);
assert.match(panel, /timeStyle: 'short'/);
assert.match(panel, /recording_subtitle', presentation\.duration, dateText, timeText/);
assert.doesNotMatch(panel, /Text\(recording\.name\)/);
assert.match(strings, /"recording_user_facing_name", "value": "Recording %d"/);
assert.match(strings, /"recording_subtitle", "value": "%s %s, %s"/);
assert.match(tests, /1h 1m 1s/);
assert.match(tests, /first segment duration and date/);

console.log('recordingPresentation=ordinal-first-segment-hms-local-date-time');
