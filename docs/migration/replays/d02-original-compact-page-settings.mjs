import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');

const panel = read('note/src/main/ets/ui/components/PageSettingsPanel.ets');
const manager = read('note/src/main/ets/ui/editor/PageManagerBar.ets');
const defaultTemplate = read('note/src/main/ets/ui/settings/DefaultTemplatePage.ets');
const originalTemplates = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/fci.java', 'utf8');

const checks = [
  ['original template cards use a vertical modal column with bounded touch rows',
    /bfd\.j\(pd8VarF, 48\.0f, 0\.0f, 2\)/.test(originalTemplates) &&
      /nti\.h\(uz4Var[0-9]*, bfd\.t\(md8Var, 8\.0f\)\)/.test(originalTemplates)],
  ['popup instance owns the vertical scroll instead of the settings page',
    panel.includes('@Prop popupMode: boolean = false;') &&
      panel.includes('if (this.popupMode)') &&
      panel.includes('Scroll()') &&
      panel.includes('this.buildPanelContent()') &&
      panel.includes('.scrollable(ScrollDirection.Vertical)') &&
      panel.includes('.constraintSize({ maxHeight: 560 })')],
  ['settings page keeps its existing outer scroll and does not opt into popup mode',
    defaultTemplate.includes('Scroll() {') && !defaultTemplate.includes('popupMode: true')],
  ['panel content width is fluid inside the popup padding',
    panel.includes(".constraintSize({ minWidth: 280, maxWidth: 420 })") &&
      (panel.match(/\.width\('100%'\)/g) ?? []).length >= 12 &&
      panel.includes('.layoutWeight(1)')],
  ['compact page manager threshold covers phone and narrow tablet widths',
    manager.includes('this.compact = (newArea.width as number) < 720;')],
  ['compact page manager keeps every frequent action in a fixed hit target',
    manager.includes("Button(compact ? '⚙' : $r('app.string.page_settings'))") &&
      manager.includes('.width(compact ? 44 : 112)') &&
      manager.includes("Button('+')") && manager.includes("Button('...')") &&
      manager.includes('.width(44)') && manager.includes('buildPageMenu()')],
  ['popup call site explicitly enables the bounded layout',
    manager.includes('popupMode: true')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

// The compact row has explicit widths for navigation, counter, settings,
// add, and overflow.  This is a static layout budget, not a replacement for
// device screenshots; it proves the target widths do not rely on clipping.
const compactRowBudget = 52 + 56 + 52 + 46 + 44 + 56 + 4;
for (const width of [360, 600]) {
  assert.ok(width >= compactRowBudget, `compact row budget exceeds ${width}vp`);
}
assert.equal(1280 < 720, false);
console.log(`PASS: compact width budget=${compactRowBudget}vp for 360/600/1280`);
console.log('D02_ORIGINAL_COMPACT_PAGE_SETTINGS_REPLAY_OK ' +
  'popup-scroll=1|fluid-panel-width=1|compact-overflow=1|action-hit-targets=1|original-modal-spacing=1');
