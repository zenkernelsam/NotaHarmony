// Phase 698 — 原版文字色/高亮面板 HSV 取色器（rw1/t8j/hv1/ru1）移植静态 Replay。
// 证据：decompiled_1.0.3 sources/defpackage/{rw1,t8j,hv1,ru1,mli,hse,xw1,ax1,nw1}.java
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

let total = 0;
const check = (cond, label) => { total++; assert.ok(cond, label); };
const read = (p) => readFileSync(p, 'utf8');
const SRC = process.env.NOTA_SRC ?? 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';

// ---------- 原版证据钉 ----------
const ru1 = read(`${SRC}/sources/defpackage/ru1.java`);
check(ru1.includes('ColorHSV(hue=') && ru1.includes('te5.B('),
  'ru1 = ColorHSV(hue,sat,colorValue) + te5.B to-color');

const mli = read(`${SRC}/sources/defpackage/mli.java`);
check(mli.includes('rw1.c(a2dVarN, ix4Var, new ru1('),
  'mli.c: color panel = rw1.c(items, onColor, ru1 seed)');
check(mli.includes('Color.RGBToHSV'),
  'mli.c: seeds ru1 from current color via RGBToHSV');
check(mli.includes('new xw1(') && mli.includes('zw1.a'),
  'mli.c: panel items include EyeDropper + RecentColors markers');

const hse = read(`${SRC}/sources/defpackage/hse.java`);
check((hse.match(/mli\.c\(cw1Var/g) ?? []).length >= 2,
  'hse cases 1+2: highlight + foreground panels both render mli.c');

const rw1 = read(`${SRC}/sources/defpackage/rw1.java`);
check(rw1.includes('ix4Var.invoke(new iu1(j))'),
  'rw1.h: selection applies color immediately');
check(rw1.includes('ui_tools__colors') && rw1.includes('ui_tools__recent_colors'),
  'rw1: Colors header + recent-colors row');

const hv1 = read(`${SRC}/sources/defpackage/hv1.java`);
check(hv1.includes('rw1.g("ColorPicker"'),
  'hv1: HSV picker wrapped as named ColorPicker sub-panel');
check((hv1.match(/new ru1\(fFloatValue/g) ?? []).length >= 3,
  'hv1: drag callbacks update ru1(h,s,v) components');

const t8j = read(`${SRC}/sources/defpackage/t8j.java`);
check((t8j.match(/PointerInputEventHandler/g) ?? []).length >= 2,
  't8j: pointer-input drag regions (SV square + hue strip)');

const xw1 = read(`${SRC}/sources/defpackage/xw1.java`);
check(xw1.includes('EyeDropper(onConfirm='), 'xw1 = EyeDropper item');
const ax1 = read(`${SRC}/sources/defpackage/ax1.java`);
check(ax1.includes('RemoveHighlight(onRemove='), 'ax1 = RemoveHighlight item');

// ---------- Harmony 实现钉 ----------
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
check(overlay.includes('@State showHsvSheet: boolean = false') &&
  overlay.includes('@State hsvTarget: number = 0'),
  'overlay: HSV sheet state + target (0=fg 1=hl)');
check(overlay.includes('private hsvComponentsToArgb(h: number, s: number, v: number): number'),
  'overlay: hsvComponentsToArgb = te5.B equivalent');
check(overlay.includes('private seedHsvFromArgb(argb: number): void'),
  'overlay: seedHsvFromArgb = Color.RGBToHSV equivalent');
check(overlay.includes('private openHsvSheet(target: number): void') &&
  overlay.includes('this.seedHsvFromArgb(this.hsvSeedColor())'),
  'overlay: sheet seeds HSV from current color (mli.c)');
check(overlay.includes('private confirmHsvColor(): void') &&
  overlay.includes('this.toggleHighlightColor(color)') &&
  overlay.includes('this.pickTextColor(color)'),
  'overlay: Apply dispatches to highlight/foreground pickers');
check(overlay.includes('colors: [[0xFFFFFFFF, 0.0], [0x00FFFFFF, 1.0]]'),
  'overlay: SV square horizontal white->transparent (saturation)');
check(overlay.includes('colors: [[0x00000000, 0.0], [0xFF000000, 1.0]]'),
  'overlay: SV square vertical transparent->black (value)');
check(overlay.includes('this.hueBaseColor()'),
  'overlay: hue base color drives SV square + thumbs');
check(overlay.includes('this.hsvS * 240 - 6') &&
  overlay.includes('(1 - this.hsvV) * 160 - 6'),
  'overlay: SV thumb positioned by sat/val');
check(overlay.includes('this.hsvS = Math.max(0, Math.min(1, t.x / 240))') &&
  overlay.includes('this.hsvV = 1 - Math.max(0, Math.min(1, t.y / 160))'),
  'overlay: SV onTouch maps coords -> sat/val (t8j pointer region)');
check(overlay.includes('0xFFFF0000, 0.0') && overlay.includes('0xFFFF00FF, 0.833'),
  'overlay: hue strip rainbow gradient');
check(overlay.includes('(t.x / 240) * 360'),
  'overlay: hue onTouch maps x -> hue 0-360');
check(overlay.includes('.bindSheet(this.showHsvSheet, this.buildHsvSheet()'),
  'overlay: HSV sheet bound');
check(overlay.includes("value: $r('app.string.color_custom')"),
  'overlay: highlight menu gains Custom item');
check(overlay.includes('this.openHsvSheet(0)') &&
  overlay.includes('this.openHsvSheet(1)'),
  'overlay: both surfaces open the shared HSV sheet');

console.log(`D02_ORIGINAL_TEXT_HSV_PICKER_REPLAY_OK TOTAL=${total} FAILED=0`);
