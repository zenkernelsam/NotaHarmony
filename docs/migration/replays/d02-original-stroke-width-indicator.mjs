// Phase 1384 — original stroke-width indicator (swd/x5f/z5c).
// The width button renders a ui_tools__strokeindicator_<style>_size<N> glyph
// (brushStyle x width tier) as outline-ring + inner-fill, not the raw number.
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/editor/EditorToolbar.ets'), 'utf8');
const ind = readFileSync(join(root, 'note/src/main/ets/ui/components/StrokeIndicators.ets'), 'utf8');

let pass = 0, fail = 0;
function t(name, cond) { if (cond) pass++; else { fail++; console.log('FAIL', name); } }

// --- StrokeIndicators map: 12 glyphs (4 styles x 3 tiers), fill+outline ---
for (const s of ['mono', 'taper', 'dash', 'dot']) {
  for (const sz of ['s', 'm', 'l']) {
    t(`glyph strokeind_${s}_${sz}`, ind.includes(`'strokeind_${s}_${sz}': { fill:`));
  }
}
t('map uses 24x6 viewport', /vw: 24, vh: 6/.test(ind));

// --- style mapping: BrushStyle ordinal -> mono/taper/dash/dot (y31 0..3) ---
t('maps MONO->mono (default)', /let style = 'mono'/.test(src));
t('maps TAPER->taper', /case BrushStyle\.TAPER: style = 'taper'/.test(src));
t('maps DASH->dash', /case BrushStyle\.DASH: style = 'dash'/.test(src));
t('maps DOT->dot', /case BrushStyle\.DOT: style = 'dot'/.test(src));

// --- tier mapping: x5f.c nearest-preset index, thirds -> s/m/l ---
t('tier uses widthWells', /widthWells/.test(src));
t('tier third = len/3 min 1', /Math\.max\(1, Math\.floor\(wells\.length \/ 3\)\)/.test(src));
t('tier s/m/l thirds', /idx < third \? 's' : \(idx < third \* 2 \? 'm' : 'l'\)/.test(src));
t('selection mode uses selectionWidth', /isSelectionActive\(\) \? this\.selectionWidth : this\.viewModel\.brushWidth/.test(src));

// --- render: outline ring (theme) beneath inner fill (brush/selection color) ---
const btnIdx = src.indexOf('粗细按钮（原版 strokeindicator');
t('width button present', btnIdx >= 0);
const btn = src.slice(btnIdx, btnIdx + 1200);
t('renders outline ring in textPrimary', /commands\(this\.strokeIndicator\(\)\.outline\)[\s\S]*?textPrimary/.test(btn));
t('renders inner fill in brush/selection color', /commands\(this\.strokeIndicator\(\)\.fill\)[\s\S]*?colorToHex/.test(btn));
t('fill picks selection vs brush color', /isSelectionActive\(\) \?\s*this\.selectionColor : this\.viewModel\.brushColor/.test(btn));
t('shape uses strokeind viewport', /viewPort\(\{ x: 0, y: 0, width: this\.strokeIndicator\(\)\.vw/.test(btn));
t('numeric width preserved as a11y text', /\.accessibilityText\(\(this\.viewModel\.isSelectionActive\(\)/.test(btn));
t('no longer shows number as label', !/Button\(\(this\.viewModel\.isSelectionActive\(\) \? this\.selectionWidth :[\s\S]*?\.toString\(\)\)/.test(btn));

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
