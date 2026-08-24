import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const disappearStart = page.indexOf('  aboutToDisappear(): void {');
const activateStart = page.indexOf('  private activatePage(): number {', disappearStart);
assert.ok(disappearStart !== -1 && activateStart > disappearStart);
const teardown = page.slice(disappearStart, activateStart);
assert.match(teardown,
  /if \(this\.thumbnailRequestTimer >= 0\) \{\s+clearTimeout\(this\.thumbnailRequestTimer\);\s+this\.thumbnailRequestTimer = -1;\s+\}/);

const requestStart = page.indexOf('  private requestVisibleThumbnail(noteId: string): void {');
const assetEnd = page.indexOf('  // T-039：文件夹操作', requestStart);
assert.ok(requestStart !== -1 && assetEnd > requestStart);
const request = page.slice(requestStart, assetEnd);
assert.match(request, /const expectedLifecycleGeneration: number = this\.lifecycleGeneration;\s+this\.thumbnailRequestTimer = setTimeout\(\(\) => \{\s+this\.thumbnailRequestTimer = -1;\s+if \(!this\.pageActive \|\| this\.lifecycleGeneration !== expectedLifecycleGeneration\) \{\s+return;\s+\}\s+this\.refreshThumbnails\(\)\.catch/);

const sortStart = page.indexOf('  private setSortMode(mode: NoteSortMode): void {');
const themeStart = page.indexOf('  private setThemeMode(mode: ThemeMode): void {', sortStart);
assert.ok(sortStart !== -1 && themeStart > sortStart);
const sort = page.slice(sortStart, themeStart);
assert.match(sort, /if \(!this\.pageActive \|\| this\.viewModel === null\) \{\s+return;\s+\}/);
for (const effect of [
  'this.viewModel.setSortMode(mode);',
  'this.refreshThumbnails().catch',
  'pref.putSync(this.PREF_SORT_KEY, mode);',
]) {
  const effectIndex = sort.indexOf(effect);
  const guardIndex = sort.indexOf('if (!this.pageActive || this.viewModel === null) {');
  assert.ok(effectIndex > guardIndex, effect);
}

console.log('D02_LIBRARY_PREFERENCE_THUMBNAIL_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
