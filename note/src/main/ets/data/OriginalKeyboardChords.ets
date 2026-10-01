// 原版硬件键盘快捷键模型（Phase 1407）——与文本编辑 keymap（phase-1255，
// hke/k09/syh）不同，此表覆盖应用级（MainActivity.dispatchKeyEvent →
// vla.a → bma.a → lra.handleNavigationShortcut / if2）与画布级
// （f2 case5 = bd8.onKeyEvent → bd8.B + f2 兜底链）两条硬件键盘通路。
//
// 原版 qa8 = KeyChord{keyCode, ctrl, alt, shift}——四维等值精确匹配
// （vla.b 以事件四元组做 Map 查表，Ctrl+N+Shift 不会命中 Ctrl+N）。
// 原版双参数构造 qa8(i, mask) 的 mask 位是"反向"的：(mask&2)==0→ctrl，
// (mask&4)==0→alt，(mask&8)==0→shift；即 vla.a 的 mask=12（0b1100）=
// {ctrl:true, alt:false, shift:false}，qa8(111,14) = 纯 ESC 无修饰。
//
// Android → HarmonyOS keyCode 对照（@ohos.multimodalInput.keyCode.d.ts）：
//   KEYCODE_0..9        7..16   → 2000..2009
//   KEYCODE_A..Z        29..54  → 2017..2042
//   KEYCODE_COMMA       55      → 2043
//   KEYCODE_MINUS       69      → 2057
//   KEYCODE_EQUALS      70      → 2058
//   KEYCODE_SLASH       76      → 2064
//   KEYCODE_PLUS        81      → 2066
//   KEYCODE_ESCAPE      111     → 2070
//   KEYCODE_MOVE_HOME   122     → 2081
//   KEYCODE_MOVE_END    123     → 2082
//   KEYCODE_NUMPAD_0..9 144..153→ 2103..2112
//   KEYCODE_NUMPAD_SUBTRACT 156 → 2115
//   KEYCODE_NUMPAD_ADD  157     → 2116
// 原版 dispatch 于 ACTION_UP（lxm.a(db8.o(event),1)）；Harmony 对应
// KeyType.Up——单次击键在松开时触发一次，不会因按住重复触发。

export interface OriginalKeyChord {
  keyCode: number;
  ctrl: boolean;
  alt: boolean;
  shift: boolean;
}

// 事件修饰键状态（event.getModifierKeyState(['ctrl'|'alt'|'shift'])，
// 与 TextBlockOverlay 既有实现同一写法）。
export function keyChordCtrl(event: KeyEvent): boolean {
  return event.getModifierKeyState !== undefined &&
    event.getModifierKeyState(['ctrl']);
}

export function keyChordAlt(event: KeyEvent): boolean {
  return event.getModifierKeyState !== undefined &&
    event.getModifierKeyState(['alt']);
}

export function keyChordShift(event: KeyEvent): boolean {
  return event.getModifierKeyState !== undefined &&
    event.getModifierKeyState(['shift']);
}

// qa8.equals 等价：键码 + 三修饰键四维全等。
export function matchKeyChord(event: KeyEvent, chord: OriginalKeyChord): boolean {
  return event.keyCode === chord.keyCode &&
    keyChordCtrl(event) === chord.ctrl &&
    keyChordAlt(event) === chord.alt &&
    keyChordShift(event) === chord.shift;
}

// === 应用级（vla.a，library 表；mask=12 → 仅 Ctrl） ===

// qa8(42,12) → xla.a = app__kbd_shortcut_new_note → lra mqa 建笔记。
export const ORIGIN_CHORD_NEW_NOTE: OriginalKeyChord = {
  keyCode: 2030, ctrl: true, alt: false, shift: false
};

// vla.b = qa8(42,4) = {N, ctrl, !alt, shift} = app__kbd_shortcut_new_window。
// 原版 MainActivity 在无多窗口启动器时仍消费该和弦（"New Window chord
// dropped" 日志 + return true）——Harmony 同等处理：消费、无操作。
export const ORIGIN_CHORD_NEW_WINDOW: OriginalKeyChord = {
  keyCode: 2030, ctrl: true, alt: false, shift: true
};

// qa8(55,12) → zla.a = kbd_shortcut_open_settings → lra.U(null)。
export const ORIGIN_CHORD_OPEN_SETTINGS: OriginalKeyChord = {
  keyCode: 2043, ctrl: true, alt: false, shift: false
};

// qa8(40,12) → wla.a = kbd_shortcut_back_to_library——原版把 feed 滚动/锚定
// 至最后一个 j19 分区之后的笔记段；Harmony 的库内等价 = 回到 All Notes 根。
export const ORIGIN_CHORD_BACK_TO_LIBRARY: OriginalKeyChord = {
  keyCode: 2028, ctrl: true, alt: false, shift: false
};

// qa8(76,12) → yla.a = kbd_shortcut_open_help → lra.U(qw6.INSTANCE)。
// Harmony 无帮助路由 → fail-closed：消费、无操作（原版该和弦同样被消费）。
export const ORIGIN_CHORD_OPEN_HELP: OriginalKeyChord = {
  keyCode: 2064, ctrl: true, alt: false, shift: false
};

// cma.a 帮助表中的 qa8(111,14) = 纯 ESC = kbd_shortcut_dismiss_deselect
// （NAVIGATION 组）——库内取消多选 / 编辑器内取消选区。
export const ORIGIN_CHORD_DISMISS: OriginalKeyChord = {
  keyCode: 2070, ctrl: false, alt: false, shift: false
};

// === 画布级（bd8.B / f2 case5 兜底链） ===
// bd8.B 的分支谓词只测 db8.r（ctrl）/db8.s（shift），alt 不参与判定——
// 与 vla 表的精确四元组不同。以下判定函数保留该差异（shift/alt 忽略处
// 与原分支一致）。

// pa8.v(70=) | t(81+) | e0(157 num+) → F(1.2f)：Ctrl+= / Ctrl++ / Ctrl+num+
export const ORIGIN_ZOOM_IN_KEYCODES: number[] = [2058, 2066, 2116];

// pa8.u(69 -) | d0(156 num-) → F(0.8333333f) = ÷1.2
export const ORIGIN_ZOOM_OUT_KEYCODES: number[] = [2057, 2115];

// pa8.j(7=0) | c0(144 num0) → ad8 → mfc.D(1.0/current, center)：重置 100%
export const ORIGIN_ZOOM_RESET_KEYCODES: number[] = [2000, 2103];

// pa8.R(122)/S(123) → jp8 byte2/byte1：Ctrl+Home 顶部 / Ctrl+End 底部
export const ORIGIN_KEYCODE_MOVE_HOME: number = 2081;
export const ORIGIN_KEYCODE_MOVE_END: number = 2082;

// pa8.A(34=F) → pc8(OpenSearch) + egj；pa8.z(33=E) Ctrl+Shift → rc8(ShowShare)；
// pa8.E(44=P) Ctrl+Shift → oc8(OpenContentManager)；pa8.F(46=R) → sc8(ToggleRecording)
export const ORIGIN_KEYCODE_F: number = 2022;
export const ORIGIN_KEYCODE_E: number = 2021;
export const ORIGIN_KEYCODE_P: number = 2032;
export const ORIGIN_KEYCODE_R: number = 2034;

// f2 兜底链：bd8.h0=pa8.K(54=Z) Ctrl→E()undo，+Shift→C()redo；
// pa8.J(53=Y) Ctrl→redo；pa8.x(31=C)/V(278 COPY)→copy；
// pa8.I(52=X)/U(277 CUT)→cut；pa8.H(50=V)/W(279 PASTE)→paste（Ctrl+Alt+V→qc8）。
// Harmony 对等键码：COPY=2620 / PASTE=2622 / CUT=2624（原序 CUT/COPY/PASTE=277/278/279）。
export const ORIGIN_KEYCODE_Z: number = 2042;
export const ORIGIN_KEYCODE_Y: number = 2041;
export const ORIGIN_KEYCODE_C: number = 2019;
export const ORIGIN_KEYCODE_X: number = 2040;
export const ORIGIN_KEYCODE_V: number = 2038;
export const ORIGIN_KEYCODE_COPY: number = 2620;
export const ORIGIN_KEYCODE_PASTE: number = 2622;
export const ORIGIN_KEYCODE_CUT: number = 2624;

// i0 = pa8.k..s = ofk.e(8..16) = KEYCODE_1..9 —— Ctrl+1..9（非 numpad）
// → cxi(index) → 第 N 个可见工具（sti.c.e + sti.d.e 顺序）。
export const ORIGIN_TOOL_SELECT_DIGIT_BASE: number = 2001;
export const ORIGIN_TOOL_SELECT_DIGIT_END: number = 2009;

// k0 = ofk.e(308..311) 厂商键 + G() 设备门（S-Pen 遥控）→ D() 前工具切换
// ——Harmony 无对应硬件通路 → fail-closed 登记（ADR-1343）。

// === 判定函数（bd8.B / f2 谓词语义） ===

// bd8.B 顶部分支：ctrl + 键码 ∈ 集合（shift/alt 不参与）。
export function isCtrlKeyIn(event: KeyEvent, keyCodes: number[]): boolean {
  return keyChordCtrl(event) && keyCodes.indexOf(event.keyCode) >= 0;
}

// f2 兜底：Ctrl+1..9 = 工具快选（db8.r && !db8.s；alt 不判）。
export function toolSelectDigitIndex(event: KeyEvent): number {
  if (!keyChordCtrl(event) || keyChordShift(event)) {
    return -1;
  }
  const idx: number = event.keyCode - ORIGIN_TOOL_SELECT_DIGIT_BASE;
  return idx >= 0 && idx < 9 ? idx : -1;
}
