// Phase 699 — 原版最近色行（zw1/sw1/ms0/rw1.f）移植静态 Replay。
// 证据：decompiled_1.0.3 sources/defpackage/{zw1,sw1,ms0,rw1,mli}.java
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

let total = 0;
const check = (cond, label) => { total++; assert.ok(cond, label); };
const read = (p) => readFileSync(p, 'utf8');
const SRC = process.env.NOTA_SRC ?? 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';

// ---------- 原版证据钉 ----------
const zw1 = read(`${SRC}/sources/defpackage/zw1.java`);
check(zw1.includes('RecentColors'), 'zw1 = RecentColors panel item');

const sw1 = read(`${SRC}/sources/defpackage/sw1.java`);
check(sw1.includes('UiState(recentColors='),
  'sw1 = UiState{recentColors List}');

const ms0 = read(`${SRC}/sources/defpackage/ms0.java`);
check(ms0.includes('new iu1(kkf.d(((bhb) it.next()).b))'),
  'ms0: bhb records -> iu1 colors (persisted recents flow)');

const mli = read(`${SRC}/sources/defpackage/mli.java`);
check(mli.includes('a2dVar.add(zw1.a)'),
  'mli.c: panel adds zw1 RecentColors item');

const rw1 = read(`${SRC}/sources/defpackage/rw1.java`);
check(rw1.includes('ui_tools__recent_colors') && rw1.includes('ui_tools__recents'),
  'rw1.f: Recent colors row with recents icon');
check(rw1.includes('7 - list2.size()'),
  'rw1.f: recents row capped/padded to 7 slots');

// ---------- Harmony 实现钉 ----------
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
check(overlay.includes("import { preferences } from '@kit.ArkData'"),
  'overlay: preferences import');
check(overlay.includes('@State colorRecents: number[] = []'),
  'overlay: colorRecents state');
check(overlay.includes("preferences.getPreferences(\n      getContext(this), 'text_color_recents')"),
  'overlay: persisted via text_color_recents store');
check(overlay.includes('private async loadColorRecents(): Promise<void>') &&
  overlay.includes('this.loadColorRecents().catch'),
  'overlay: recents loaded in aboutToAppear');
check(overlay.includes('slice(0, 7)'),
  'overlay: recents capped at 7 (rw1.f)');
check(overlay.includes('this.colorRecents =\n      [color, ...this.colorRecents.filter'),
  'overlay: record = dedupe + unshift front');
check(overlay.includes('store.putSync(\'recents\', JSON.stringify(this.colorRecents))') &&
  overlay.includes('await store.flush()'),
  'overlay: recents persisted on change');
check(overlay.includes('this.recordRecentColor(color);\n    this.showTextColorSheet = false') ||
  overlay.includes('this.recordRecentColor(color);'),
  'overlay: record on pick');
check((overlay.match(/this\.recordRecentColor\(color\);/g) ?? []).length >= 2,
  'overlay: recordRecentColor hooked into fg + hl pick paths');
check(overlay.includes('private pickRecentColor(color: number): void') &&
  overlay.includes('this.hsvTarget === 1'),
  'overlay: pickRecentColor dispatches by hsvTarget');
check(overlay.includes('private buildColorRecentsRow(): void'),
  'overlay: buildColorRecentsRow = rw1.f row');
check((overlay.match(/this\.buildColorRecentsRow\(\)/g) ?? []).length >= 2,
  'overlay: recents row mounted in text color sheet + HSV sheet');
check(overlay.includes('this.hsvTarget = 0;\n              this.showTextColorSheet = true'),
  'overlay: text color sheet sets hsvTarget=0');

console.log(`D02_ORIGINAL_RECENT_COLORS_REPLAY_OK TOTAL=${total} FAILED=0`);
