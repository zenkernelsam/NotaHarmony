import assert from 'node:assert/strict';
import fs from 'node:fs';

const panel = fs.readFileSync('note/src/main/ets/ui/components/PageSettingsPanel.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const bar = fs.readFileSync('note/src/main/ets/ui/editor/PageManagerBar.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(panel, /@Prop photoImportLeaseActive: boolean = false;/);

const panelBuildStart = panel.indexOf('  build() {');
const panelBuildEnd = panel.indexOf('\n  @Builder\n  SpacingSettings', panelBuildStart);
assert.ok(panelBuildStart >= 0 && panelBuildEnd > panelBuildStart);
const body = panel.slice(panelBuildStart, panelBuildEnd);

assert.match(body,
  /if \(!this\.busy && !this\.photoImportLeaseActive &&\s+!this\.sharedBusy && !this\.spacingSaveBusy\) \{\s+this\.draft = stageOriginalTemplateSize/);
assert.equal(body.match(/\.enabled\(!this\.busy && !this\.photoImportLeaseActive &&\s+!this\.sharedBusy && !this\.spacingSaveBusy\)/g)?.length, 1);
assert.equal(body.match(/if \(!this\.busy && !this\.photoImportLeaseActive &&\s+!this\.sharedBusy && !this\.spacingSaveBusy &&\s+this\.draft\.orientation !== PageOrientation\.(PORTRAIT|LANDSCAPE)\)/g)?.length, 2);
assert.match(body, /\.enabled\(!this\.busy && !this\.photoImportLeaseActive\)/);
const applyTemplate = panel.slice(
  panel.indexOf('  private applyTemplate('),
  panel.indexOf('\n  }\n', panel.indexOf('  private applyTemplate(')));
assert.match(applyTemplate,
  /if \(this\.busy \|\| this\.photoImportLeaseActive \|\|\s+this\.sharedBusy \|\| this\.spacingSaveBusy\) \{\s+return;\s+\}/);

const toggleFavorite = panel.slice(
  panel.indexOf('  private async toggleFavorite('),
  panel.indexOf('\n  }\n', panel.indexOf('  private async toggleFavorite(')));
assert.match(toggleFavorite,
  /const store: OriginalPaperSettingsStore \| null = this\.paperStore;\s+if \(store === null \|\| this\.busy \|\| this\.photoImportLeaseActive \|\|\s+this\.sharedBusy \|\| this\.spacingSaveBusy\) \{\s+return;\s+\}/);
const favoriteButton = body.slice(
  body.indexOf("Button(this.isTemplateFavorite(tpl) ? '★' : '☆')"),
  body.indexOf('.accessibilityText(this.isTemplateFavorite(tpl) ?', body.indexOf("Button(this.isTemplateFavorite(tpl) ? '★' : '☆')")));
assert.match(favoriteButton,
  /\.enabled\(!this\.busy && !this\.photoImportLeaseActive &&\s+!this\.sharedBusy && !this\.spacingSaveBusy &&\s+this\.paperStore !== null\)/);

const toggleSpacingSettings = panel.slice(
  panel.indexOf('  private toggleSpacingSettings('),
  panel.indexOf('\n  }\n', panel.indexOf('  private toggleSpacingSettings(')));
assert.match(toggleSpacingSettings,
  /if \(this\.busy \|\| this\.photoImportLeaseActive \|\|\s+this\.sharedBusy \|\| this\.spacingSaveBusy \|\| this\.paperStore === null\) \{\s+return;\s+\}/);
const spacingButton = body.slice(
  body.indexOf("Button('⋯')"),
  body.indexOf(".accessibilityText($r('app.string.template_settings'))", body.indexOf("Button('⋯')")));
assert.match(spacingButton,
  /\.enabled\(!this\.busy && !this\.photoImportLeaseActive &&\s+!this\.sharedBusy && !this\.spacingSaveBusy &&\s+this\.paperStore !== null\)/);

const previewSharedSpacing = panel.slice(
  panel.indexOf('  private previewSharedSpacing('),
  panel.indexOf('\n  }\n', panel.indexOf('  private previewSharedSpacing(')));
assert.match(previewSharedSpacing,
  /if \(this\.paperStore === null \|\| this\.busy \|\| this\.sharedBusy \|\| this\.spacingSaveBusy \|\|\s+this\.photoImportLeaseActive \|\| this\.spacingTemplate !== template \|\|\s+template === PaperTemplate.PLAIN\) \{\s+return;\s+\}/);
const saveSharedSpacing = panel.slice(
  panel.indexOf('  private async saveSharedSpacing('),
  panel.indexOf('\n  }\n', panel.indexOf('  private async saveSharedSpacing(')));
assert.match(saveSharedSpacing,
  /if \(store === null \|\| this\.busy \|\| this\.sharedBusy \|\| this\.spacingSaveBusy \|\|\s+this\.photoImportLeaseActive \|\| template === PaperTemplate.PLAIN\) \{\s+return;\s+\}/);

function methodBody(name) {
  const start = panel.indexOf(`  private ${name}(`);
  assert.ok(start >= 0, `${name} exists`);
  return panel.slice(start, panel.indexOf('\n  }\n', start));
}

assert.match(methodBody('selectLegacyPaper'),
  /if \(this\.busy \|\| this\.photoImportLeaseActive \|\|\s+this\.sharedBusy \|\| this\.spacingSaveBusy\) \{\s+return;\s+\}/);
assert.match(methodBody('activateCustomColor'),
  /if \(this\.busy \|\| this\.photoImportLeaseActive \|\|\s+this\.sharedBusy \|\| this\.spacingSaveBusy\) \{\s+return;\s+\}/);
for (const name of ['updateCustomHue', 'updateCustomSaturation', 'updateCustomValue']) {
  const body = methodBody(name);
  assert.match(body,
    /if \(this\.busy \|\| this\.photoImportLeaseActive \|\|\s+this\.sharedBusy \|\| this\.spacingSaveBusy\) \{\s+return;\s+\}\s+/,
    `${name} rejects busy, shared lease, and save states`);
}

assert.equal(
  panel.match(/private updateCustom(?:Hue|Saturation|Value)\(value: number\): void \{\s+if \(this\.photoImportLeaseActive\) \{/g)?.length ?? 0,
  0,
  'custom color events no longer reject only the shared lease');
assert.equal(
  panel.match(/private updateCustom(?:Hue|Saturation|Value)\(value: number\): void \{\s+if \(this\.busy \|\| this\.photoImportLeaseActive \|\|\s+this\.sharedBusy \|\| this\.spacingSaveBusy\) \{/g)?.length,
  3,
  'all custom color channels fail closed');
const closeCustomColor = body.slice(
  body.indexOf(".accessibilityText($r('app.string.paper_custom_color_close'))"),
  body.indexOf('\n          })',
    body.indexOf(".accessibilityText($r('app.string.paper_custom_color_close'))")));
assert.match(closeCustomColor,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.customColorExpanded = false;/);

for (const [name, forward] of [
  ['favorite', 'this.toggleFavorite(tpl);'],
  ['spacing settings', 'this.toggleSpacingSettings(tpl);'],
]) {
  const clickStart = body.indexOf('.onClick(() => {', body.indexOf(forward) - 260);
  const clickEnd = body.indexOf('})', clickStart);
  const callback = body.slice(clickStart, clickEnd);
  const guard = callback.indexOf('if (this.photoImportLeaseActive) {');
  const guardReturn = callback.indexOf('return;', guard);
  const forwardIndex = callback.indexOf(forward, guardReturn);
  assert.ok(guard >= 0 && guardReturn > guard && forwardIndex > guardReturn,
    `${name} button rejects shared lease`);
}

(function assertCustomColorButton() {
  const marker = "Button($r('app.string.paper_custom_color'))";
  const buttonStart = body.indexOf(marker);
  assert.ok(buttonStart >= 0, 'custom color button');
  const buttonEnd = body.indexOf('\n        Blank()', buttonStart);
  assert.ok(buttonEnd > buttonStart, 'custom color button bounds');
  const section = body.slice(buttonStart, buttonEnd);
  const guard = section.indexOf('if (this.photoImportLeaseActive) {');
  const guardReturn = section.indexOf('return;', guard);
  const forwardIndex = section.indexOf('this.activateCustomColor();', guardReturn);
  assert.ok(guard >= 0 && guardReturn > guard && forwardIndex > guardReturn,
    'custom color button rejects shared lease');
})();

const popupCall = bar.slice(bar.indexOf('    PageSettingsPanel({'), bar.indexOf('    })', bar.indexOf('    PageSettingsPanel({')));
assert.match(popupCall, /busy: this\.busy,/);
assert.match(popupCall, /photoImportLeaseActive: this\.photoImportLeaseActive,/);
const settingsButton = bar.slice(bar.indexOf('  SettingsButton(compact: boolean) {'), bar.indexOf('  private buildPageMenu', bar.indexOf('  SettingsButton(compact: boolean) {')));
assert.match(settingsButton, /if \(!this\.photoImportLeaseActive\) \{\s+this\.PageSettingsBuilder\(\)\s+\}/);

console.log(
  'D02_PAGE_SETTINGS_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=25 FAILED=0');
