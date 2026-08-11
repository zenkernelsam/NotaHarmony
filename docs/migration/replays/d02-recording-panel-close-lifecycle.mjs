import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const originalPanel = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/i5h.java', 'utf8');
const originalToggle = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/b49.java', 'utf8');
const originalEditorCommand = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/z39.java', 'utf8');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');

const originalStopSites = `${originalPanel}\n${originalToggle}`.match(/\.i\(ujb\.a\)/g) ?? [];
assert.equal(originalStopSites.length, 2);
assert.match(originalPanel,
  /boolean z3 = \(\(qjb\)[\s\S]*instanceof pjb[\s\S]*if \(z3\)[\s\S]*i\(ujb\.a\)[\s\S]*else[\s\S]*i\(new tjb\(\)\)/);
assert.match(originalToggle,
  /if \(!\(xjbVar\.T\.I\.getValue\(\) instanceof pjb\)\)[\s\S]*i\(new tjb\(\)\)[\s\S]*else[\s\S]*i\(ujb\.a\)/);
assert.match(originalEditorCommand, /case 0:[\s\S]*\(\(xjb\) obj\)\.i\(new tjb\(\)\)/);

const closeMethod = page.match(/private closeRecordings\(\): void \{[\s\S]*?\n  \}/);
assert.ok(closeMethod);
assert.match(closeMethod[0], /this\.showRecordings = false/);
assert.doesNotMatch(closeMethod[0], /session\.stop|finishRecordingSession|capture\.release/);
assert.match(page, /leaveEditor\(\)[\s\S]*await this\.finishRecordingSession\(\)/);
assert.match(page, /aboutToDisappear\(\)[\s\S]*this\.finishRecordingSession\(\)/);

console.log('recordingPanelClose=hide-continues-capture-editor-exit-saves');
