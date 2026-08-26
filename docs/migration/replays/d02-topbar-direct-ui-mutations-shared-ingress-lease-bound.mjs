import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const topBarStart = page.indexOf('      // 顶部导航行（48vp）');
const toolbarEnd = page.indexOf('      // 工具栏', topBarStart);
assert.ok(topBarStart >= 0 && toolbarEnd > topBarStart);
const topBar = page.slice(topBarStart, toolbarEnd);

const changeIndex = topBar.indexOf('.onChange((value: string) => {');
const inputChange = topBar.slice(changeIndex, topBar.indexOf('.onSubmit', changeIndex));
assert.match(inputChange,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.titleDraft = truncateOriginalNoteTitleDraft\(value\);/);

const textIndex = topBar.indexOf("Text(this.noteTitle.length > 0 ? this.noteTitle : $r('app.string.untitled_note'))");
const clickIndex = topBar.indexOf('.onClick(() => {', textIndex);
const titleClickEnd = topBar.indexOf('this.editingTitle = true;', clickIndex);
const titleClick = topBar.slice(clickIndex, titleClickEnd);
assert.match(titleClick,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}/);
assert.match(titleClick, /if \(this\.pageLoadFailed \|\| this\.pageLoading\)/);

const recordingsToggle = topBar.slice(
  topBar.indexOf("Button($r('app.string.recordings'))"));
assert.match(recordingsToggle,
  /\.enabled\(!this\.pageLoading && !this\.pageLoadFailed &&\s+!this\.photoImportLeaseActive\)/);
assert.match(recordingsToggle,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+if \(this\.showRecordings\) \{\s+this\.closeRecordings\(\);\s+\} else \{\s+this\.showRecordings = true;/);

const commitTitle = page.slice(
  page.indexOf('private async commitTitle(requested: string, generation: number): Promise<void> {'),
  page.indexOf('private publishTitleDraft'));
assert.match(commitTitle,
  /if \(this\.photoImportLeaseActive \|\| this\.pageStructureLeaseActive\) \{\s+return;/);

console.log(
  'D02_TOPBAR_DIRECT_UI_MUTATIONS_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
