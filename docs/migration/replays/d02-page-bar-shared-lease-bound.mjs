import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const bar = fs.readFileSync('note/src/main/ets/ui/editor/PageManagerBar.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('      PageManagerBar({');
const end = page.indexOf('\n      }\n    }', start);
assert.ok(start >= 0 && end > start);
const call = page.slice(start, end);
assert.match(call, /photoImportLeaseActive: this\.photoImportLeaseActive/);
assert.match(call, /busy: this\.photoImportLeaseActive \|\| this\.pageOperationBusy/);

for (const token of [
  '@Prop photoImportLeaseActive: boolean = false;',
  '.enabled(!this.busy && !this.photoImportLeaseActive)',
  '.enabled(!this.busy && !this.photoImportLeaseActive &&',
]) {
  assert.ok(bar.includes(token), `page manager bar binds ${token}`);
}
assert.equal(bar.match(/!this\.photoImportLeaseActive/g)?.length >= 6, true);

function guardedClick(marker, forwardToken) {
  const clickStart = bar.indexOf(marker);
  assert.ok(clickStart >= 0, marker);
  const bodyEnd = bar.indexOf('\n      })', clickStart) === -1 ?
    bar.indexOf('\n          })', clickStart) :
    bar.indexOf('\n      })', clickStart);
  assert.ok(bodyEnd > clickStart, `${marker} bounds`);
  const body = bar.slice(clickStart, bodyEnd);
  assert.match(body,
    /if \(this\.busy \|\| this\.photoImportLeaseActive\) \{/,
    `${forwardToken} callback guard`);
}

guardedClick('.accessibilityText($r(\'app.string.add_page\'))\n          .onClick(() => {', 'add');
guardedClick('NavigationButton', 'navigation');
guardedClick("Button($r('app.string.delete'))", 'delete');

for (const [name, marker] of [
  ['compact add', '.accessibilityText($r(\'app.string.add_page\'))\n          .onClick(() => {'],
  ['regular move previous', "Button($r('app.string.move_page_earlier'))"],
  ['regular move next', "Button($r('app.string.move_page_later'))"],
  ['regular add', "Button($r('app.string.add_page'))"],
  ['regular delete', "Button($r('app.string.delete'))"],
]) {
  const buttonStart = bar.indexOf(marker);
  assert.ok(buttonStart >= 0, `${name} marker`);
  const buttonEnd = bar.indexOf('\n        Button(', buttonStart);
  const rowEnd = bar.indexOf('\n    }\n    .width', buttonStart);
  const bound = buttonEnd === -1 || (rowEnd !== -1 && rowEnd < buttonEnd) ?
    rowEnd : buttonEnd;
  assert.ok(bound > buttonStart, `${name} bounds`);
  const body = bar.slice(buttonStart, bound);
  assert.match(body, /if \(this\.busy \|\| this\.photoImportLeaseActive\) \{/,
    `${name} busy callback`);
}

const navigationStart = bar.indexOf('NavigationButton(label: string, previous: boolean)');
const navigationEnd = bar.indexOf('\n  }\n\n  @Builder', navigationStart);
assert.ok(navigationStart >= 0 && navigationEnd > navigationStart);
assert.match(bar.slice(navigationStart, navigationEnd),
  /if \(this\.busy \|\| this\.photoImportLeaseActive\) \{/);

const settingsStart = bar.indexOf("Button(compact ? '⚙' : $r('app.string.page_settings'))");
const settingsEnd = bar.indexOf('\n  }\n\n  private buildPageMenu', settingsStart);
assert.ok(settingsStart >= 0 && settingsEnd > settingsStart);
assert.match(bar.slice(settingsStart, settingsEnd),
  /if \(this\.busy \|\| this\.photoImportLeaseActive\) \{/);
guardedClick("Button($r('app.string.move_page_earlier'))", 'move previous');
guardedClick("Button($r('app.string.move_page_later'))", 'move next');
guardedClick("Button(compact ? '⚙' : $r('app.string.page_settings'))", 'settings');

assert.equal(
  bar.match(/if \(!this\.busy && !this\.photoImportLeaseActive\) \{/g)?.length ?? 0,
  0,
  'inverted page manager guards removed');
assert.equal(
  bar.match(/if \(this\.busy \|\| this\.photoImportLeaseActive\) \{/g)?.length,
  13,
  'all direct page manager callbacks fail closed');

const backgroundStart = page.indexOf(
  '  private async applyNoteBackgroundSettings(');
assert.ok(backgroundStart >= 0);
const backgroundEnd = page.indexOf(
  '\n  private async runPageOperation', backgroundStart);
assert.ok(backgroundEnd > backgroundStart);
const background = page.slice(backgroundStart, backgroundEnd);
const guardStart = background.indexOf('if (');
const guardEnd = background.indexOf('{\n      return;', guardStart);
const guard = background.slice(guardStart, guardEnd);
for (const [name, token] of [
  ['shared photo ingress lease', 'this.photoImportLeaseActive'],
  ['structure lease', 'this.pageStructureLeaseActive'],
  ['repository gate', 'this.pageRepo === null'],
]) {
  assert.ok(guard.includes(token), `background applies ${name}`);
}

console.log('D02_PAGE_BAR_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=24 FAILED=0');
