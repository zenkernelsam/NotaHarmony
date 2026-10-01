// Phase 1419 — 原版选择工具 Box/Free 双模式 toggle parity
// 证据链：rnm.c = i6n 二级工具条中 SELECTION 的 kqi 选项项（iw4 包裹、
// e52.X3 排序槽位）；Row(c90 8dp 间距) 内两枚 w5n.b：
//   [Box]    icon=j87.H.h=ui_designsystem__selectbox_outline,
//            label=ui_tools__select_box_label("Box"),
//            cd=ui_tools__select_rect_mode, selected=!freehand,
//            onClick=w5e(bz5,9) -> invoke(FALSE) 置矩形模式；
//   [Free]   icon=j87.H.i=ui_designsystem__selectfreehand_outline,
//            label=ui_tools__select_freehand_label("Free"),
//            cd=ui_tools__select_freehand_mode, selected=freehand,
//            onClick=w5e(bz5,10) -> invoke(TRUE) 置自由模式。
// w5n.b 本体 = x5n.a 按钮（shape t8a.F + cd=str2 语义）包裹
// vqf 内容：i87.b 图标 + d4i.b 文本，选中态 j=nta.a.d.a accent 底
// （非选中 p52.j 中性色）。原版该选项行无前置 "Selection" 文本标签。
// Harmony 此前为单一 toggle 钮（标签=当前模式），改为原版双钮结构。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage';
const R = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values';
const H = 'C:/HarmonyProject/NotaHarmony/note/src/main';

const checks = [];
const check = (name, cond) => {
  assert.equal(cond, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const rnm = fs.readFileSync(`${S}/rnm.java`, 'utf8');
const w5n = fs.readFileSync(`${S}/w5n.java`, 'utf8');
const w5e = fs.readFileSync(`${S}/w5e.java`, 'utf8');
const j87 = fs.readFileSync(`${S}/j87.java`, 'utf8');
const strings = fs.readFileSync(`${R}/strings.xml`, 'utf8');
const toolbar = fs.readFileSync(`${H}/ets/ui/editor/EditorToolbar.ets`, 'utf8');
const glyphs = fs.readFileSync(`${H}/ets/ui/components/ToolGlyphs.ets`, 'utf8');
const en = fs.readFileSync(`${H}/resources/base/element/string.json`, 'utf8');
const zh = fs.readFileSync(`${H}/resources/zh_CN/element/string.json`, 'utf8');

// ---- 原版锚点 ----
check('rnm.c Box 钮 = j87.H.h + select_box_label + select_rect_mode',
  /hdc hdcVarA = \(\(j87\) se3\.x\(nc6Var\)\.H\)\.h\.a\(nc6Var\);[\s\S]{0,400}?select_box_label[\s\S]{0,120}?select_rect_mode/.test(rnm));
check('rnm.c Free 钮 = j87.H.i + select_freehand_label + select_freehand_mode',
  /hdc hdcVarA2 = \(\(j87\) se3\.x\(nc6Var\)\.H\)\.i\.a\(nc6Var\);[\s\S]{0,400}?select_freehand_label[\s\S]{0,120}?select_freehand_mode/.test(rnm));
check('j87.H.h = selectbox_outline', j87.includes('ui_designsystem__selectbox_outline'));
check('j87.H.i = selectfreehand_outline', j87.includes('ui_designsystem__selectfreehand_outline'));
check('Box 钮 selected=!z2（z2=freehand）', /boolean z3 = !z2;[\s\S]{0,300}?w5n\.b\(hdcVarA/.test(rnm));
check('Free 钮 selected=z2', /w5n\.b\(hdcVarA2, strW2, strW3, z2,/.test(rnm));
check('w5e case9 -> FALSE（矩形）', /case 9:\s*\n\s*bz5Var\.invoke\(Boolean\.FALSE\)/.test(w5e));
check('w5e case10 -> TRUE（自由）', /case 10:\s*\n\s*bz5Var\.invoke\(Boolean\.TRUE\)/.test(w5e));
check('w5n.b 选中态 j=nta.a.d.a accent', /if \(z\) \{[\s\S]{0,200}?nta\.c\(nc6Var2\)\.a\.d\.a/.test(w5n));
check('select_box_label = "Box"',
  strings.includes('name="ui_tools__select_box_label">Box<'));
check('select_freehand_label = "Free"',
  strings.includes('name="ui_tools__select_freehand_label">Free<'));

// ---- Harmony 实现 ----
const isSelIdx = toolbar.indexOf('isSelectionActive()');
const styleIdx = toolbar.indexOf('SelectionStyleButton($r(\'app.string.brush_style_variable\')', isSelIdx);
const modeRow = toolbar.slice(isSelIdx, styleIdx);
check('模式行 = Row({ space: 8 })', modeRow.includes('Row({ space: 8 })'));
check('Box 钮调 SelectionModeButton + selectbox glyph + Box label + rect cd',
  /SelectionModeButton\('selectbox', \$r\('app\.string\.select_box_label'\),\s*\$r\('app\.string\.select_rect_mode'\), !this\.viewModel\.selectionIsFreehand/.test(modeRow));
check('Box 钮 onTap -> setSelectionIsFreehand(false)', /select_rect_mode'\), !this\.viewModel\.selectionIsFreehand, \(\): void => \{\s*this\.viewModel\.setSelectionIsFreehand\(false\);/.test(modeRow));
check('Free 钮调 SelectionModeButton + selectfreehand glyph + Free label + freehand cd',
  /SelectionModeButton\('selectfreehand', \$r\('app\.string\.select_freehand_label'\),\s*\$r\('app\.string\.select_freehand_mode'\), this\.viewModel\.selectionIsFreehand/.test(modeRow));
check('Free 钮 onTap -> setSelectionIsFreehand(true)', /select_freehand_mode'\), this\.viewModel\.selectionIsFreehand, \(\): void => \{\s*this\.viewModel\.setSelectionIsFreehand\(true\);/.test(modeRow));
check('模式行不含单一 toggle 旧锚 Button(selectionIsFreehand ?',
  !modeRow.includes('Button(this.viewModel.selectionIsFreehand'));

const bIdx = toolbar.indexOf('SelectionModeButton(glyph');
const bEnd = toolbar.indexOf('\n  }\n', bIdx);
const builder = toolbar.slice(bIdx, bEnd);
check('SelectionModeButton 渲染 ToolGlyph + Text(label)', builder.includes('ToolGlyph({') && builder.includes('Text(label)'));
check('SelectionModeButton 选中态 accent 底', builder.includes('selected ? this.resolveTokens().accent : this.resolveTokens().control'));
check('SelectionModeButton a11y = modeA11y', builder.includes('.accessibilityText(modeA11y)'));
check('SelectionModeButton 受 toolStateLoading+lease 门控',
  builder.includes('.enabled(!this.viewModel.toolStateLoading &&') && builder.includes('this.photoImportLeaseActive'));
check('glyph selectbox 入 TOOL_GLYPHS', glyphs.includes("'selectbox': { f: `M1.375,17"));
check('glyph selectfreehand 入 TOOL_GLYPHS', glyphs.includes("'selectfreehand': { f: `M10.271,16.78"));

// ---- 资源 ----
check('en select_box_label="Box"', en.includes('"name": "select_box_label", "value": "Box"'));
check('en select_freehand_label="Free"', en.includes('"name": "select_freehand_label", "value": "Free"'));
check('zh select_box_label/select_freehand_label', zh.includes('"select_box_label"') && zh.includes('"select_freehand_label"'));
check('旧 freehand/rectangle 资源键已随单一 toggle 一并清除',
  !en.includes('"name": "freehand"') && !en.includes('"name": "rectangle"') &&
  !zh.includes('"freehand"') && !zh.includes('"rectangle"'));

console.log(`\nD02_ORIGINAL_SELECTION_MODE_TOGGLE_REPLAY_OK TOTAL=${checks.length} FAILED=0`);
