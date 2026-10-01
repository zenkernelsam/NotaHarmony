// Phase 1386 (1.0.3 x4j: icon-only wave glyphs) — SUPERSEDED by Phase 1437:
// 1.4.2 azm.c/u4h 渲染等宽描边卡片 = 24dp ui_designsystem__line_style_* 图标
// + 可见文本标签（Variable/Fixed/Dashed/Dotted，yxi:79-82 顺序）。
// 本 fixture 现钉 1.4.2 实现；1.0.3 brushstyle_* 波形资产保留于
// LINE_STYLE_GLYPHS 旁的 BRUSH_STYLE_GLYPHS（不再消费）。
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/editor/EditorToolbar.ets'), 'utf8');
const g = readFileSync(join(root, 'note/src/main/ets/ui/components/BrushStyleGlyphs.ets'), 'utf8');
const strEn = readFileSync(join(root, 'note/src/main/resources/base/element/string.json'), 'utf8');
const strZh = readFileSync(join(root, 'note/src/main/resources/zh_CN/element/string.json'), 'utf8');

let pass = 0, fail = 0;
function t(name, cond) { if (cond) pass++; else { fail++; console.log('FAIL', name); } }

// --- LINE_STYLE_GLYPHS: 4 个 1.4.2 line_style_* 矢量 ---
for (const s of ['variable', 'fixed', 'dashed', 'dotted']) {
  t(`glyph line_style_${s}`, g.includes(`'line_style_${s}': { d:`));
}
t('variable is filled', /'line_style_variable': \{ d: `[^`]+`, stroked: false/.test(g));
t('fixed is stroked sw=1.25', /'line_style_fixed': \{ d: `[^`]+`, stroked: true, sw: 1\.25/.test(g));
t('dashed is stroked', /'line_style_dashed': \{ d: `[^`]+`, stroked: true/.test(g));
t('dotted is filled', /'line_style_dotted': \{ d: `[^`]+`, stroked: false/.test(g));
t('fixed keeps +0.625 translate via negative viewport origin',
  /vx: -0\.625, vy: -0\.625/.test(g));

// --- BrushStyle -> line_style_* 映射（o81 序 Mono/Taper/Dash/Dot） ---
t('TAPER->line_style_variable', /case BrushStyle\.TAPER: key = 'line_style_variable'/.test(src));
t('DASH->line_style_dashed', /case BrushStyle\.DASH: key = 'line_style_dashed'/.test(src));
t('DOT->line_style_dotted', /case BrushStyle\.DOT: key = 'line_style_dotted'/.test(src));
t('MONO->line_style_fixed (default)', /let key = 'line_style_fixed'/.test(src));

// --- 标签串（u4h labelRes 直名） ---
for (const [k, v] of [['brush_style_variable', 'Variable'], ['brush_style_fixed', 'Fixed'],
                      ['brush_style_dashed', 'Dashed'], ['brush_style_dotted', 'Dotted']]) {
  t(`en ${k}=${v}`, strEn.includes(`"name": "${k}"`) && strEn.includes(`"value": "${v}"`));
}
t('zh brush_style_variable=可变', strZh.includes('"name": "brush_style_variable", "value": "可变"'));

// --- 顺序：Variable(Taper) 居首，Fixed(Mono) 次之（yxi:79-82） ---
const penRowIdx = src.indexOf('supportsBrushStyleControls()');
const penRow = src.slice(penRowIdx, penRowIdx + 900);
{
  const iv = penRow.indexOf('brush_style_variable'), ix = penRow.indexOf('brush_style_fixed');
  const id = penRow.indexOf('brush_style_dashed'), io = penRow.indexOf('brush_style_dotted');
  t('pen row order TAPER,MONO,DASH,DOT', iv >= 0 && ix > iv && id > ix && io > id);
}
const selRowIdx = src.indexOf('this.SelectionStyleButton($r(\'app.string.brush_style_variable\')');
const selRow = src.slice(selRowIdx, selRowIdx + 600);
{
  const iv = selRow.indexOf('brush_style_variable'), ix = selRow.indexOf('brush_style_fixed');
  const id = selRow.indexOf('brush_style_dashed'), io = selRow.indexOf('brush_style_dotted');
  t('selection row same order', iv >= 0 && ix > iv && id > ix && io > id);
}

// --- 卡片语义：描边 + 等宽 + icon+label + a11y + 动作不变 ---
const sbIdx = src.indexOf('StyleButton(label: Resource, style: BrushStyle)');
const ssbIdx = src.indexOf('SelectionStyleButton(label: Resource, style: BrushStyle)');
t('StyleButton present', sbIdx >= 0);
t('SelectionStyleButton present', ssbIdx >= 0);
const sb = src.slice(sbIdx, ssbIdx);
const ssb = src.slice(ssbIdx, ssbIdx + 1400);
t('StyleButton renders LineStyleIconView', /this\.LineStyleIconView\(style,/.test(sb));
t('StyleButton shows Text(label)', /Text\(label\)/.test(sb));
t('StyleButton accent border when selected', /borderColor\(this\.viewModel\.brushStyle === style/.test(sb));
t('StyleButton transparent border otherwise', /Color\.Transparent/.test(sb));
t('StyleButton equal-weight card', /\.layoutWeight\(1\)/.test(sb));
t('StyleButton keeps setBrushStyle', /this\.viewModel\.setBrushStyle\(style\)/.test(sb));
t('SelectionStyleButton renders icon+label', /this\.LineStyleIconView\(style,/.test(ssb) && /Text\(label\)/.test(ssb));
t('SelectionStyleButton keeps taper gate', /style !== BrushStyle\.TAPER \|\| this\.selectionVariableStyleEnabled/.test(ssb));
t('SelectionStyleButton keeps onSelectionStyle', /this\.onSelectionStyle\(style\)/.test(ssb));
t('style name kept as a11y text', /\.accessibilityText\(label\)/.test(sb) && /\.accessibilityText\(label\)/.test(ssb));

// --- 1.0.3 波形资产仍登记在 BRUSH_STYLE_GLYPHS（历史证据），但不再被消费 ---
t('1.0.3 wave glyphs retained as evidence', /'brushstyle_mono': \{ d:/.test(g));
t('1.0.3 glyph view no longer consumed', !src.includes('BRUSH_STYLE_GLYPHS['));
// 1.0.3 旧标签键 style_mono/taper/dash/dots 已随卡片化清除（同 selection-mode 惯例）
for (const k of ['style_mono', 'style_taper', 'style_dash', 'style_dots']) {
  t(`dead key ${k} removed`, !strEn.includes(`"name": "${k}"`) && !strZh.includes(`"name": "${k}"`));
}

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
