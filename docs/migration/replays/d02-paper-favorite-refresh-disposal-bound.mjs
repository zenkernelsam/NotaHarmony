import assert from 'node:assert/strict';
import fs from 'node:fs';

const panel = fs.readFileSync('note/src/main/ets/ui/components/PageSettingsPanel.ets', 'utf8').replaceAll('\r\n', '\n');

const favoriteStart = panel.indexOf('private async toggleFavorite(template: PaperTemplate): Promise<void> {');
const favoriteEnd = panel.indexOf('private spacingIndex(template: PaperTemplate): number {', favoriteStart);
assert.ok(favoriteStart !== -1 && favoriteEnd > favoriteStart, 'toggleFavorite body');
const body = panel.slice(favoriteStart, favoriteEnd);

const tryBodyStartIndex = body.indexOf('try {') + 'try {'.length;
const writeEndIndex = body.indexOf('await store.removeFavorite(candidate);');
assert.notEqual(writeEndIndex, -1, 'favorite remove await');
const listRefreshCandidateIndex = body.indexOf('await store.listFavorites();', writeEndIndex);
assert.notEqual(listRefreshCandidateIndex, -1, 'refresh await exists');

const firstGuardIndex = body.indexOf('if (this.panelDisposed) {', writeEndIndex);
assert.ok(firstGuardIndex > writeEndIndex && firstGuardIndex < listRefreshCandidateIndex,
  'refresh await follows durable write and precedes disposal guard');
const refreshEndIndex = listRefreshCandidateIndex + 'await store.listFavorites();'.length;
const secondGuardIndex = body.indexOf('if (this.panelDisposed) {', refreshEndIndex);
const publishIndex = body.indexOf('this.favorites = favorites;', secondGuardIndex);
assert.ok(refreshEndIndex < secondGuardIndex && secondGuardIndex < publishIndex,
  'guard follows refresh await and precedes publication');

const catchIndex = body.lastIndexOf('} catch (error) {');
const catchLogIndex = body.indexOf('console.error(', catchIndex);
const failureToastIndex = body.indexOf('this.showSharedPaperFailure();', catchLogIndex);
assert.ok(catchLogIndex > catchIndex && failureToastIndex > catchLogIndex, 'failure feedback remains guarded by existing catch path');

console.log('D02_PAPER_FAVORITE_REFRESH_DISPOSAL_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
