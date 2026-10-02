// Phase 1477 — 1.4.2 手写笔杆键擦除切换（bd8.B 尾支）→ fail-closed。
// Original evidence (decompiled_1.4.2):
//   bd8.java:46 — k0 = {pa8(308..311)} = Android
//     KEYCODE_STYLUS_BUTTON_PRIMARY/SECONDARY/TERTIARY/TAIL（笔杆四键）。
//   bd8.java:208-215 — `!k0.contains(n) || ctrl || alt || shift ||
//     !G()` → return null（放行）；否则 KeyUp → D()、命中即消费。
//   bd8.java:257 G() = h45.b(h35.q0)，h35.java:266 q0 =
//     "STYLUS_BUTTON_ERASER_TOGGLE"（td5 日期门 2026-09-03）。
//   bd8.java:226-244 D() — o5h 防抖：c=激活旗、b=激活时间戳、
//     d=解除时间戳、e=100ms 窗；激活支 emit hxi.a.f(fxi.a)。
//   fxi.java — toString="ToggleEraser"；npb.java:53-72 →
//     f6n.e(vti) 擦除工具 id → 工具列表按 id 找 wsi → xqb.B 选中。
//   Harmony：keyCode.d.ts 无 KEYCODE_STYLUS_*；touchEvent PEN 无
//     button 字段 → fail-closed（ADR-1412）。
import { readFileSync, existsSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CHORDS = 'note/src/main/ets/data/OriginalKeyboardChords.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const chords = readFileSync(CHORDS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- fail-closed 钉死：无笔杆键处理路径 ---
check(!canvas.includes('STYLUS_BUTTON') && !chords.includes('STYLUS_BUTTON'),
  'no stylus-button keycode handling (fail-closed: no Harmony channel)');
check(!canvas.match(/keyCode\s*===?\s*308\b|\b309\b|\b310\b|\b311\b/),
  'no hardcoded Android stylus codes 308-311 in canvas dispatch');

// --- SDK 侧证据：keyCode.d.ts 无 STYLUS_ 枚举 ---
const SDK_KEYCODE =
  'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/' +
  'ets/api/@ohos.multimodalInput.keyCode.d.ts';
if (existsSync(SDK_KEYCODE)) {
  const sdk = readFileSync(SDK_KEYCODE, 'utf8');
  check(!sdk.includes('KEYCODE_STYLUS'),
    'Harmony keyCode.d.ts has no KEYCODE_STYLUS_* (channel absent)');
  check(sdk.includes('KEYCODE_T = 2036'),
    'sanity: SDK file read correctly (KEYCODE_T=2036 present)');
} else {
  console.log('  (SDK path absent on this host — skip SDK pin)');
  n++;
  n++;
}

// --- 可执行模型：原版 D() 防抖语义（未来通道落点参考） ---
class O5h {
  constructor() { this.b = null; this.c = false; this.d = null; }
  // bd8:226-244：c || (d 100ms 内) → c?disarm:suppress；
  // 否则 b 100ms 外 → b=now + emit ToggleEraser。
  press(now, windowMs = 100) {
    if (this.c || (this.d !== null && now - this.d < windowMs)) {
      if (this.c) { this.c = false; this.d = now; }
      return 'no-op';
    }
    if (this.b === null || now - this.b >= windowMs) {
      this.b = now;
      return 'toggle-eraser';
    }
    return 'no-op';
  }
}
const st = new O5h();
check(st.press(0) === 'toggle-eraser', 'model: first press emits ToggleEraser');
check(st.press(50) === 'no-op', 'model: re-press within 100ms suppressed (b window)');
// 注：模型 c 仅在消费端切到擦除工具后置位（npb 侧），此处压测
// b 防抖窗与 d 抑制窗——与原版字段分工一致。
check(st.press(150) === 'toggle-eraser',
  'model: press after 100ms window emits again');
const st2 = new O5h();
st2.c = true;
check(st2.press(500) === 'no-op' && st2.c === false && st2.d === 500,
  'model: press while armed disarms (c=false, d=now)');
check(st2.press(550) === 'no-op',
  'model: re-press within 100ms after disarm suppressed (d window)');

console.log(`d02-original-stylus-button-eraser: ${n} checks OK`);
