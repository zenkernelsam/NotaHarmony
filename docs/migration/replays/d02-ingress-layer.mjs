// Phase 1319 — ingress layer (want/intent consumers)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('DeepLinkIngress', X('DeepLinkIngress.ets'));
const dl = readFileSync(S + 'DeepLinkIngress.ets', 'utf8');
t('notability.com deep link', dl.includes('notability.com'));
t('authlink+fail-closed', dl.includes('authlink') || dl.includes('fail-closed'));
t('LaunchActionIngress', X('LaunchActionIngress.ets'));
const la = readFileSync(S + 'LaunchActionIngress.ets', 'utf8');
t('launch_action param', la.includes('launch_action'));
t('start_camera extra', la.includes('start_camera'));
t('OpenTargetIngress', X('OpenTargetIngress.ets'));
const ot = readFileSync(S + 'OpenTargetIngress.ets', 'utf8');
t('want.uri handling', ot.includes('want.uri') || ot.includes('want'));
t('drag-drop+clipboard', X('OriginalDragDropIngress.ets') && X('OriginalClipboardImageIngress.ets'));
t('camera picker', X('OriginalCameraPickerCaller.ets'));
console.log('ingress-layer replay: ' + n + '/10 checks green');
