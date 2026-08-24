import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function body(startMarker, endMarker) {
  const start = page.indexOf(startMarker);
  const end = page.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return page.slice(start, end);
}

for (const [name, text, key] of [
  ['sort', body('  private setSortMode(mode: NoteSortMode): void {',
    '  private async initData('), 'this.PREF_SORT_KEY'],
  ['theme', body('  private setThemeMode(mode: ThemeMode): void {',
    '  // 原版 folder row'), 'THEME_PREFERENCE_KEY'],
]) {
  assert.match(text, /const lifecycleGeneration: number = this\.lifecycleGeneration;/, name);
  const captureIndex = text.indexOf('const lifecycleGeneration');
  const awaitIndex = text.indexOf('await preferences.getPreferences(', captureIndex);
  const thenIndex = text.indexOf('.then((pref: preferences.Preferences) => {', captureIndex);
  const guard = text.indexOf('if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {', thenIndex);
  const putIndex = text.indexOf(`pref.putSync(${key}`, thenIndex);
  assert.ok(awaitIndex === -1 && thenIndex !== -1 && guard !== -1 && putIndex !== -1 &&
    guard < putIndex, `${name}: guard must precede preference write`);
}

console.log('D02_LIBRARY_PREFERENCE_WRITE_LIFECYCLE_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
