import assert from 'node:assert/strict';
import fs from 'node:fs';

const panel = fs.readFileSync('note/src/main/ets/ui/components/PageSettingsPanel.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const disposeStart = panel.indexOf('aboutToDisappear(): void {');
const disposeEnd = panel.indexOf('\n  private onSettingsChange', disposeStart);
assert.notEqual(disposeStart, -1);
assert.ok(disposeEnd > disposeStart);
assert.match(panel.slice(disposeStart, disposeEnd), /this\.panelDisposed = true;/);

const favoriteStart = panel.indexOf('private async toggleFavorite(template: PaperTemplate): Promise<void> {');
const spacingStart = panel.indexOf('private spacingIndex(template: PaperTemplate): number {', favoriteStart);
assert.ok(favoriteStart !== -1 && spacingStart > favoriteStart);
const favorite = panel.slice(favoriteStart, spacingStart);
const favGuards = (favorite.match(/if \(this\.panelDisposed\) \{\s+return;\s+\}/g) ?? []).length;
assert.equal(favGuards, 3);
const writeEndIndex = favorite.indexOf('await store.removeFavorite(candidate);');
assert.notEqual(writeEndIndex, -1);
const firstFavoriteGuardIndex = favorite.indexOf('if (this.panelDisposed) {', writeEndIndex);
const listRefreshIndex = favorite.indexOf('await store.listFavorites();', writeEndIndex);
assert.ok(firstFavoriteGuardIndex > writeEndIndex && firstFavoriteGuardIndex < listRefreshIndex,
  'guard precedes refresh await');
const refreshEndIndex = listRefreshIndex + 'await store.listFavorites();'.length;
const secondFavoriteGuardIndex = favorite.indexOf('if (this.panelDisposed) {', refreshEndIndex);
const favoritesPublishIndex = favorite.indexOf('this.favorites = favorites;', secondFavoriteGuardIndex);
assert.ok(refreshEndIndex < secondFavoriteGuardIndex && secondFavoriteGuardIndex < favoritesPublishIndex,
  'guard precedes favorites publication');

assert.match(favorite, /\} catch \(error\) \{\s+if \(this\.panelDisposed\) \{\s+return;\s+\}/);

const saveStart = panel.indexOf('private async saveSharedSpacing(template: PaperTemplate, rawIndex: number): Promise<void> {');
const replaceStart = panel.indexOf('private replaceBackgroundInfo(value: OriginalBackgroundInfo): void {', saveStart);
assert.ok(saveStart !== -1 && replaceStart > saveStart);
const save = panel.slice(saveStart, replaceStart);
const saveGuards = (save.match(/if \(this\.panelDisposed\) \{\s+return;\s+\}/g) ?? []).length;
assert.equal(saveGuards, 2);
assert.match(save,
  /await store\.saveSpacing\([\s\S]*?\);\s+if \(this\.panelDisposed\) \{\s+return;\s+\}/);
assert.match(save, /\} catch \(error\) \{\s+if \(this\.panelDisposed\) \{\s+return;\s+\}/);

console.log('D02_PAPER_SETTINGS_DISPOSAL_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
