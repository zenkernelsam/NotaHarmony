import assert from 'node:assert/strict';
import fs from 'node:fs';

const bar = fs.readFileSync('note/src/main/ets/ui/editor/PageManagerBar.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const deleteStart = bar.indexOf("Button($r('app.string.delete'))");
const deleteEnd = bar.indexOf('\n      }\n    }\n    .width', deleteStart);
const deleteButton = bar.slice(deleteStart, deleteEnd);
// Original de2.i compensation: Delete stays enabled at one page (the same op
// stream inserts a blank), so only the shared ingress lease gates it.
assert.match(deleteButton,
  /\.enabled\(!this\.busy && !this\.photoImportLeaseActive\)/);

const menuStart = bar.indexOf('private buildPageMenu(): MenuElement[] {');
const menuEnd = bar.indexOf('\n  }\n\n  @Builder\n  PageSettingsBuilder', menuStart);
assert.ok(menuStart >= 0 && menuEnd > menuStart);
const menu = bar.slice(menuStart, menuEnd);

const movePreviousGuard = menu.slice(
  menu.indexOf('{ value: $r(\'app.string.move_page_earlier\')'),
  menu.indexOf('this.onMovePrevious();'));
const moveNextGuard = menu.slice(
  menu.indexOf('{ value: $r(\'app.string.move_page_later\')'),
  menu.indexOf('this.onMoveNext();'));
const deleteMenuGuard = menu.slice(
  menu.indexOf("{ value: $r('app.string.delete_page')"),
  menu.indexOf('this.onDelete();'));

for (const [name, guard] of [
  ['move previous', movePreviousGuard],
  ['move next', moveNextGuard],
]) {
  assert.match(guard,
    /if \(!this\.busy && !this\.photoImportLeaseActive &&/,
    name);
}
// de2.i compensation removed the pageCount gate on delete; the menu item
// now uses the plain fail-closed shared-ingress check.
assert.match(deleteMenuGuard,
  /if \(this\.busy \|\| this\.photoImportLeaseActive\) \{/);

for (const [label, forward] of [
  ['earlier', 'this.onMovePrevious();'],
  ['later', 'this.onMoveNext();'],
]) {
  const buttonStart = bar.indexOf(`Button($r('app.string.move_page_${label}'))`);
  assert.ok(buttonStart >= 0, `${label} button`);
  const buttonEnd = bar.indexOf('\n        Button(', buttonStart);
  assert.ok(buttonEnd > buttonStart, `${label} bounds`);
  const buttonBody = bar.slice(buttonStart, buttonEnd);
  const guardStart = buttonBody.indexOf('if (this.busy || this.photoImportLeaseActive) {');
  const guardReturn = buttonBody.indexOf('return;', guardStart);
  const forwardIndex = buttonBody.indexOf(forward, guardReturn);
  assert.ok(guardStart >= 0 && guardReturn > guardStart && forwardIndex > guardReturn,
    `${label} click rejects shared ingress`);
}

console.log(
  'D02_PAGE_MANAGER_CONSISTENCY_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
