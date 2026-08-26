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

const popupCall = bar.slice(bar.indexOf('    PageSettingsPanel({'), bar.indexOf('    })', bar.indexOf('    PageSettingsPanel({')));
assert.match(popupCall, /busy: this\.busy,/);
assert.match(popupCall, /photoImportLeaseActive: this\.photoImportLeaseActive,/);
const settingsButton = bar.slice(bar.indexOf('  SettingsButton(compact: boolean) {'), bar.indexOf('  private buildPageMenu', bar.indexOf('  SettingsButton(compact: boolean) {')));
assert.match(settingsButton, /if \(!this\.photoImportLeaseActive\) \{\s+this\.PageSettingsBuilder\(\)\s+\}/);

console.log(
  'D02_PAGE_SETTINGS_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=8 FAILED=0');
