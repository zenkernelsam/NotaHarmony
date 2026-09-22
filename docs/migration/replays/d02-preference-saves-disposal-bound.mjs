import assert from 'node:assert/strict';
import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8').replaceAll('\r\n', '\n');
}

const settings = read('note/src/main/ets/ui/settings/SettingsPage.ets');
const template = read('note/src/main/ets/ui/settings/DefaultTemplatePage.ets');

for (const [name, page] of [['SettingsPage', settings], ['DefaultTemplatePage', template]]) {
  assert.match(page, /private lifecycleGeneration: number = 0;/, name);
  assert.match(page, /private pageDisposed: boolean = false;/, name);
  assert.match(page, /aboutToDisappear\(\): void \{\s+this\.pageDisposed = true;\s+\}/, name);
  const loadGuards = [...page.matchAll(/if \(this\.pageDisposed \|\| generation !== this\.loadGeneration\) \{\s+return;\s+\}/g)];
  assert.equal(loadGuards.length, 2, `${name}: success and failure load paths`);
assert.match(page, /const lifecycleGeneration: number = \+\+this\.lifecycleGeneration;/,
  `${name}: captures save generation`);
}

assert.match(settings,
  /Button\(\$r\('app\.string\.retry'\)\)\s+\.onClick\(\(\) => \{\s+if \(this\.saveBusy\) \{\s+return;\s+\}\s+this\.reloadSettings\(\);/,
  'settings retry rejects save-busy state');

assert.match(settings,
  /await store\.saveShapeDetectionEnabled\(enabled\);\s+if \(this\.pageDisposed \|\| lifecycleGeneration !== this\.lifecycleGeneration\) \{\s+return;\s+\}\s+\} catch \(e\) \{\s+if \(this\.pageDisposed \|\| lifecycleGeneration !== this\.lifecycleGeneration\) \{\s+return;\s+\}/);
// Scope to the shape-detection save path: the keep-awake setter (Phase 560)
// and the theme-mode persist (Phase 566) reuse the same guard+rollback
// vocabulary, so lastIndexOf alone would land in the wrong method.
const shapeSaveStart = settings.indexOf('setShapeDetectionEnabled');
const shapeSaveEnd = settings.indexOf('\n  private ', shapeSaveStart + 10);
const shapeSave = settings.slice(shapeSaveStart, shapeSaveEnd === -1 ? undefined : shapeSaveEnd);
for (const effect of ['this.shapeDetectionEnabled = previous;', 'editor_setting_save_failed']) {
  const guardIndex = shapeSave.lastIndexOf('lifecycleGeneration !== this.lifecycleGeneration');
  assert.ok(shapeSave.indexOf(effect) > guardIndex, effect);
}

assert.match(template,
  /await store\.saveSelectedDefaultTemplate\(originalDefaultTemplateFromSettings\(next\)\);\s+if \(this\.pageDisposed \|\| lifecycleGeneration !== this\.lifecycleGeneration\) \{\s+return;\s+\}/);
for (const effect of ['this.settings = previous;', 'default_template_save_failed']) {
  const guardIndex = template.lastIndexOf('lifecycleGeneration !== this.lifecycleGeneration');
  assert.ok(template.indexOf(effect) > guardIndex, effect);
}
const saveToast = template.indexOf("promptAction.showToast({ message: $r('app.string.default_template_saved')");
const saveGuard = template.indexOf('lifecycleGeneration !== this.lifecycleGeneration', template.indexOf('await store.saveSelectedDefaultTemplate'));
assert.ok(saveToast > saveGuard);

console.log('D02_PREFERENCE_SAVES_DISPOSAL_BOUND_REPLAY_OK TOTAL=11 FAILED=0');
