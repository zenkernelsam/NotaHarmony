// Phase 679 — 原版 eyedropper（取色器）：色彩面板开启 → 画布触摸取样 →
// 放大镜实时预览 → 松开提交颜色并自动关。
// 原版证据（decompiled_1.0.3/sources/defpackage）：
//   ac4.java    D=SHOW_EYEDROPPER(3, 无远程键)、C=EYEDROPPER_ALWAYS_
//     RECORDING(2, lsb.c=androidEyedropperAlwaysRecording)。
//   r22.java    case9 渲染 eyedropper 按钮（eye_dropper_color_picker 图标
//     + ui_tools__eyedropper 标签）。
//   lu7.java    {a=enabled, b=pick(ix4), c=dismiss(Function0)}。
//   i3.java     case12：lu7.c.invoke() 后 i8f.k(lu7.a(...,6)) 复位关。
//   q5.java     case5：lu7.b(iu1) 提交 + 同式自动关。
//   a3a.java    画布 Bitmap.getPixel(clamp) → kkf.d → iu1。
//   nui.java    放大镜 m18.n(zn9, e76 位置柄, bitmap, wx4)。
//   sc9.java    色彩面板态含 eyedropperState(k=lu7)。
//   u49.java    lu7.a 激活时 chromeFlip（工具面板翻面）。
// Harmony：EditorViewModel.eyedropperActive/ForSelection +
// setEyedropperActive；ColorPickerView eyedropper 行（selectionMode
// 透传目标）；NoteCanvasView 触摸拦截 → getImageData 取样 →
// PixelMap 放大镜（generation 防旧帧覆盖）→ commitEyedropper
// （工具色 setBrushColor / 选区色 onEyedropperSelectionColor→
// NotePage selectionInkColor+signal）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const ac4 = fs.readFileSync(`${originalRoot}sources/defpackage/ac4.java`, 'utf8');
const r22 = fs.readFileSync(`${originalRoot}sources/defpackage/r22.java`, 'utf8');
const lu7 = fs.readFileSync(`${originalRoot}sources/defpackage/lu7.java`, 'utf8');
const i3 = fs.readFileSync(`${originalRoot}sources/defpackage/i3.java`, 'utf8');
const q5 = fs.readFileSync(`${originalRoot}sources/defpackage/q5.java`, 'utf8');
const a3a = fs.readFileSync(`${originalRoot}sources/defpackage/a3a.java`, 'utf8');
const nui = fs.readFileSync(`${originalRoot}sources/defpackage/nui.java`, 'utf8');
const sc9 = fs.readFileSync(`${originalRoot}sources/defpackage/sc9.java`, 'utf8');
const stringsXml = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const vm = fs.readFileSync('note/src/main/ets/ui/editor/EditorViewModel.ets', 'utf8');
const picker = fs.readFileSync('note/src/main/ets/ui/components/ColorPicker.ets', 'utf8');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8');
const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8');
const en = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zh = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 原版证据钉 ---
check(ac4.includes('"EYEDROPPER_ALWAYS_RECORDING", 2'), 'ac4.C always-recording flag');
check(ac4.includes('"SHOW_EYEDROPPER", 3'), 'ac4.D show-eyedropper flag');
check(r22.includes('ui_tools__eye_dropper_color_picker') &&
  r22.includes('ui_tools__eyedropper'), 'r22 case9 eyedropper button');
check(lu7.includes('public final boolean a') && lu7.includes('public final ix4 b') &&
  lu7.includes('public final Function0 c'), 'lu7 {enabled,pick,dismiss}');
check(i3.includes('lu7Var.c.invoke()') && /i8fVar\.k\(lu7\.a\(lu7Var2?, null, null, 6\)\)/
  .test(i3), 'i3 case12 dismiss→auto-off');
check(q5.includes('.b.invoke(new iu1') && /i8fVar\.k\(lu7\.a\(lu7Var, null, null, 6\)\)/
  .test(q5), 'q5 case5 pick→auto-off');
check(a3a.includes('.getPixel(') && a3a.includes('new iu1(kkf.d('),
  'a3a bitmap.getPixel→iu1');
check(nui.includes('m18.n(') && nui.includes('Bitmap'), 'nui loupe render');
check(sc9.includes('eyedropperState'), 'sc9 panel state carries lu7');
check(stringsXml.includes('<string name="ui_tools__eyedropper">Eyedropper</string>'),
  'original Eyedropper label');

// --- Harmony 状态机钉 ---
check(vm.includes('eyedropperActive: boolean = false') &&
  vm.includes('eyedropperForSelection: boolean = false'), 'vm eyedropper state');
check(/setEyedropperActive\(active: boolean, forSelection: boolean = false\)/.test(vm),
  'vm setEyedropperActive signature');
check(/setEyedropperActive\(false\);[\s\S]{0,200}refreshWells/.test(vm),
  'tool-switch clears eyedropper');

// --- 面板按钮钉 ---
check(picker.includes("$r('app.string.eyedropper')"), 'picker eyedropper row');
check(picker.includes('!this.viewModel.eyedropperActive, this.selectionMode'),
  'picker toggle passes selectionMode');
check(toolbar.includes('setEyedropperActive(false)'), 'toolbar deactivates on close');

// --- 画布钉 ---
check(canvas.includes('this.viewModel.eyedropperActive') &&
  canvas.includes('onEyedropperTouch(event)'), 'canvas touch intercept');
check(canvas.includes('onEyedropperTouch') && canvas.includes('sampleEyedropper') &&
  canvas.includes('commitEyedropper') && canvas.includes('cancelEyedropper'),
  'canvas eyedropper handlers');
check(canvas.includes('getImageData(sx, sy, swVp, shVp)'), 'canvas pixel sampling');
// Phase 753 — vp 绘制空间修正：getImageData 入参为 vp、ImageData 宽高为
// 物理 px（HarmonyOS ImageData 文档）。旧实现按 px 假设：触点乘 density
// 取址 + vp 边长当像素行距 → 取样偏移且 PixelMap 尺寸失配。
check(canvas.includes('24 / density'),
  'eyedropper samples a 24-physical-px neighborhood (nui)');
check(!canvas.includes('Math.round(xVp * density)'),
  'touch coords stay in vp (no density pre-multiplication)');
check(/cyPx \* dw \+ cxPx|cy \* dw \+ cx/.test(canvas),
  'pixel index strides by physical-px row width (dw)');
check(/width: dw, height: dh/.test(canvas),
  'loupe PixelMap sized to ImageData physical px dims');
check(canvas.includes('image.createPixelMap') && canvas.includes('eyedropperLoupeMap'),
  'loupe pixelmap');
check(canvas.includes('eyedropperSampleGeneration'), 'sampling generation guard');
check(canvas.includes('onEyedropperSelectionColor(color)') &&
  canvas.includes('eyedropperForSelection'), 'selection-color commit branch');
check(canvas.includes('this.viewModel.setBrushColor(color)'), 'tool-color commit branch');
check(page.includes('onEyedropperSelectionColor: (color: number)') &&
  page.includes('this.selectionInkColor = color;'), 'NotePage selection commit');

// --- 字符串钉 ---
check(en.includes('"eyedropper"') && en.includes('"Eyedropper"'), 'en eyedropper');
check(zh.includes('"eyedropper"') && zh.includes('取色器'), 'zh eyedropper');

console.log(`TOTAL=${n}`);
