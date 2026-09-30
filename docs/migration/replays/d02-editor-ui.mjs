// Phase 1338 — editor UI surface (toolbar + overlays)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const E = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/editor/';
const C = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/components/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const tb = readFileSync(E + 'EditorToolbar.ets', 'utf8');
t('EditorToolbar', tb.includes('EditorToolbar') || tb.includes('Scroll'));
t('original string key', tb.includes('data_onboarding') || tb.includes('feature_note'));
t('toolbox dialog', existsSync(E + 'ToolboxSettingsDialog.ets'));
t('canvas+page+zoom', existsSync(E + 'NoteCanvasView.ets') && existsSync(E + 'NoteZoomView.ets'));
t('page manager', existsSync(E + 'PageManagerBar.ets'));
t('recording panel', existsSync(E + 'RecordingPanel.ets'));
t('color picker', existsSync(C + 'ColorPicker.ets'));
t('selection overlay', existsSync(C + 'SelectionOverlay.ets'));
t('math editor overlay', existsSync(C + 'MathEditorOverlay.ets'));
t('pdf password dialog', existsSync(C + 'PdfPasswordDialog.ets'));
console.log('editor-ui replay: ' + n + '/10 checks green');
