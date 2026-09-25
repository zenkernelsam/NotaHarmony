// D02 ui_tools__ 族尾部收口 — Phase 720（ADR-0668）。
// 可移植项：yed "Width: %1$d" 资源化（原 'Width: ' 字面量）、
// jfh 选区模式双图标 a11y（select_rect/freehand_mode）。
// 边界登记：MEDIA/RECORD 工具箱画布工具（rz1.q 默认集 O/P → x4f/e5f
// 状态），Harmony 经工具栏菜单+录音面板交付同名能力；stroke/fill/
// no_fill（hx1/r22 形状属性页签，Harmony 无形状样式 sheet）；
// color_options（o4j chevron a11y，无节点）。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const yed = read(`${JADX}/sources/defpackage/yed.java`);
const jfh = read(`${JADX}/sources/defpackage/jfh.java`);
const rz1 = read(`${JADX}/sources/defpackage/rz1.java`);
const x82 = read(`${JADX}/sources/defpackage/x82.java`);
const hx1 = read(`${JADX}/sources/defpackage/hx1.java`);
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const slider = read('note/src/main/ets/ui/components/WidthSlider.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版证据 ---
check(strings.includes('ui_tools__width') &&
  /ui_tools__width">Width: %1\$d</.test(strings), '原版 width 格式化串');
check((yed.match(/ui_tools__width/g) || []).length >= 4,
  'yed 四处渲染 Width: %1$d');
check(jfh.includes('ui_tools__select_box_label') &&
  jfh.includes('ui_tools__select_rect_mode') &&
  jfh.includes('ui_tools__select_freehand_label') &&
  jfh.includes('ui_tools__select_freehand_mode'),
  'jfh 选区双模式 label+mode a11y');
check(rz1.includes('a6f.O') && rz1.includes('a6f.P'),
  'rz1.q 默认工具箱含 MEDIA/RECORD');
check(/case 6:[\s\S]{0,80}ui_tools__media/.test(x82) &&
  /case 7:[\s\S]{0,80}ui_tools__record/.test(x82),
  'x82 a6f→label 映射含 MEDIA/RECORD');
check(hx1.includes('ui_tools__stroke') && hx1.includes('ui_tools__fill'),
  'hx1 形状属性 STROKE/FILL 页签');

// --- Harmony 移植 ---
check(slider.includes("$r('app.string.ui_tools_width'"),
  'WidthSlider 宽度读数走资源');
check(!slider.includes("'Width: ' +"), 'Width: 字面量消除');
check(/ui_tools_width',\s*\n?\s*Math\.round/.test(slider),
  '宽度入参 Math.round 整型化');
check(toolbar.includes("$r('app.string.select_freehand_mode')") &&
  toolbar.includes("$r('app.string.select_rect_mode')") &&
  /accessibilityText\(this\.viewModel\.selectionIsFreehand/.test(toolbar),
  '选区模式钮挂双 a11y 模式描述');
check(en.includes('"ui_tools_width", "value": "Width: %d"'),
  'en ui_tools_width');
check(zh.includes('"ui_tools_width"') && zh.includes('"select_rect_mode"') &&
  zh.includes('"select_freehand_mode"'), 'zh 三键');

console.log(`TOTAL=${total} FAILED=0`);
