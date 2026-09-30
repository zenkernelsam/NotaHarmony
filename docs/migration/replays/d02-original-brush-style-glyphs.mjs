// Phase 1386 — original brush-style picker shows brushstyle_* wave glyphs (x4j).
// Each option renders a 44x24 stroke-style wave (mono stroked, taper/dash/dot
// filled), not a text label; the style name is the accessibility text.
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/editor/EditorToolbar.ets'), 'utf8');
const g = readFileSync(join(root, 'note/src/main/ets/ui/components/BrushStyleGlyphs.ets'), 'utf8');

let pass = 0, fail = 0;
function t(name, cond) { if (cond) pass++; else { fail++; console.log('FAIL', name); } }

// --- BrushStyleGlyphs map: 4 wave glyphs (x4j ui_tools__brushstyle_*) ---
for (const s of ['mono', 'taper', 'dash', 'dot']) {
  t(`glyph brushstyle_${s}`, g.includes(`'brushstyle_${s}': { d:`));
}
t('mono is stroked (fillColor=0)', /'brushstyle_mono': \{ d: `[^`]+`, stroked: true, sw: 3/.test(g));
t('taper is filled', /'brushstyle_taper': \{ d: `[^`]+`, stroked: false/.test(g));
t('glyphs use 44x24 viewport', /vw: 44, vh: 24/.test(g));

// --- style->key mapping (BrushStyle ordinal -> brushstyle_* key) ---
t('TAPER->brushstyle_taper', /case BrushStyle\.TAPER: key = 'brushstyle_taper'/.test(src));
t('DASH->brushstyle_dash', /case BrushStyle\.DASH: key = 'brushstyle_dash'/.test(src));
t('DOT->brushstyle_dot', /case BrushStyle\.DOT: key = 'brushstyle_dot'/.test(src));
t('MONO->brushstyle_mono (default)', /let key = 'brushstyle_mono'/.test(src));

// --- glyph render: stroked vs filled path + 44x24 viewport ---
t('fill when not stroked', /\.fill\(this\.brushStyleGlyph\(style\)\.stroked \? Color\.Transparent : color\)/.test(src));
t('stroke when stroked', /\.stroke\(this\.brushStyleGlyph\(style\)\.stroked \? color : Color\.Transparent\)/.test(src));
t('uses brushStyleGlyph viewport', /viewPort\(\{ x: 0, y: 0, width: this\.brushStyleGlyph\(style\)\.vw/.test(src));

// --- both style buttons now render the glyph, not text ---
const sbIdx = src.indexOf('StyleButton(label: Resource, style: BrushStyle)');
const ssbIdx = src.indexOf('SelectionStyleButton(label: Resource, style: BrushStyle)');
t('StyleButton present', sbIdx >= 0);
t('SelectionStyleButton present', ssbIdx >= 0);
const sb = src.slice(sbIdx, ssbIdx);
const ssb = src.slice(ssbIdx, ssbIdx + 1100);
t('StyleButton renders BrushStyleGlyphView', /this\.BrushStyleGlyphView\(style,/.test(sb));
t('StyleButton keeps accent/control bg', /brushStyle === style \? this\.resolveTokens\(\)\.accent/.test(sb));
t('StyleButton keeps setBrushStyle', /this\.viewModel\.setBrushStyle\(style\)/.test(sb));
t('SelectionStyleButton renders glyph', /this\.BrushStyleGlyphView\(style,/.test(ssb));
t('SelectionStyleButton keeps taper gate', /style !== BrushStyle\.TAPER \|\| this\.selectionVariableStyleEnabled/.test(ssb));
t('style name kept as a11y text', /\.accessibilityText\(label\)/.test(sb) && /\.accessibilityText\(label\)/.test(ssb));
t('no Button(label) text buttons', !/Button\(label\)/.test(sb) && !/Button\(label\)/.test(ssb));

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
