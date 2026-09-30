// Phase 1385 — original width-preset wells render a stroke-thickness sample.
// Original setting_pen_width_mini_layout -> width_view ImageView filled by the
// S-Pen SDK with a thickness sample; Harmony previously showed Text(width).
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const src = readFileSync(join(root, 'note/src/main/ets/ui/components/WidthSlider.ets'), 'utf8');

let pass = 0, fail = 0;
function t(name, cond) { if (cond) pass++; else { fail++; console.log('FAIL', name); } }

const wellIdx = src.indexOf('widthWells, (width: number, index: number)');
t('preset ForEach present', wellIdx >= 0);
const well = src.slice(wellIdx, wellIdx + 1400);

// sample is a horizontal rounded bar, height proportional to the preset width
t('sample bar height bound to width', /wellSampleHeight\(width\)/.test(well));
t('sample bar is a Row fill', /Row\(\)[\s\S]*?\.width\(20\)[\s\S]*?\.height\(this\.wellSampleHeight\(width\)\)/.test(well));
t('sample rounded to half height', /\.borderRadius\(this\.wellSampleHeight\(width\) \/ 2\)/.test(well));
t('sample tinted brush color', /\.backgroundColor\(this\.viewModel\.colorToHex\(this\.viewModel\.brushColor\)\)/.test(well));

// tier scale helper: clamp preset width into a 2..16px bar
t('helper clamps 2..16', /Math\.max\(2, Math\.min\(16, width\)\)/.test(src));

// chip chrome + behavior preserved
t('chip keeps selected accent border', /brushWidth === width \?\s*this\.resolveTokens\(\)\.accent : this\.resolveTokens\(\)\.border/.test(well));
t('chip keeps lease-guard click', /setBrushWidth\(width, index\)/.test(well));
t('chip keeps enabled lease guard', /\.enabled\(!this\.photoImportLeaseActive\)/.test(well));
t('width preserved as a11y text', /\.accessibilityText\(width\.toString\(\)\)/.test(well));

// no longer renders the number as the chip label (accessibilityText still ok)
t('no Text(width) chip label', !/(^|[^a-zA-Z])Text\(width\.toString\(\)\)/.test(well));

// the separate "Width: N" readout + slider still present
t('width readout retained', /ui_tools_width/.test(src));
t('slider retained', /Slider\(\{[\s\S]*?value: this\.selectionMode/.test(src));

console.log(`RESULT PASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
