// D02 原版权限拒绝对话框「Go to Settings」— Phase 707
// 原版 e32 case0/1：ui_permissions__go_to_settings（首按钮）+
// ui_permissions__dismiss（次按钮）。Harmony PERMISSION_DENIED 对话框
// 原本只有 Dismiss——本轮补 Go to Settings 首按钮，
// 调 requestPermissionOnSetting 打开系统权限设置页。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const e32 = read(`${JADX}/sources/defpackage/e32.java`);

const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const baseStrings = read('note/src/main/resources/base/element/string.json');
const zhStrings = read('note/src/main/resources/zh_CN/element/string.json');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版证据 ---
check(strings.includes('ui_permissions__go_to_settings') &&
  strings.includes('ui_permissions__dismiss') &&
  strings.includes('ui_permissions__microphone_access_required') &&
  strings.includes('ui_permissions__camera_access_required'),
  'original ui_permissions dialog strings');
check(e32.includes('R.string.ui_permissions__go_to_settings') &&
  e32.includes('R.string.ui_permissions__dismiss') &&
  e32.indexOf('ui_permissions__go_to_settings') < e32.indexOf('ui_permissions__dismiss'),
  'original dialog order: Go to Settings first, Dismiss second');

// --- Harmony 实现 ---
check(page.includes("app.string.microphone_permission_title") &&
  page.includes("app.string.microphone_permission_message"),
  'PERMISSION_DENIED dialog keeps title + message');
check(page.includes("$r('app.string.go_to_settings')") &&
  page.includes("$r('app.string.dismiss')"),
  'dialog renders both buttons');
check(page.indexOf("app.string.go_to_settings") < page.indexOf("app.string.dismiss"),
  'Go to Settings is the first button (original order)');
check(page.includes('abilityAccessCtrl.createAtManager()') &&
  page.includes('requestPermissionOnSetting(context') &&
  page.includes("'ohos.permission.MICROPHONE'"),
  'first button opens the system permission settings page');
check(page.includes('response.index === 0 && !this.editorDisposed'),
  'settings navigation is index-0 bound + disposal-guarded');
check(page.includes("import { common, abilityAccessCtrl } from '@kit.AbilityKit'"),
  'abilityAccessCtrl import present');
check(baseStrings.includes('"name": "go_to_settings"') &&
  zhStrings.includes('"name": "go_to_settings"'),
  'go_to_settings string in base + zh_CN');

console.log(`D02_ORIGINAL_PERMISSION_GO_TO_SETTINGS_REPLAY_OK TOTAL=${total} FAILED=0`);
