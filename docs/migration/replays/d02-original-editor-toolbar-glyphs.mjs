// Phase 1368 — editor toolbox renders original ui_designsystem__<tool> glyph
// icons (fill + outline) instead of text-only buttons.
// Original x5f main strip: cq.h(m4f, brushColor,…) tints the fill of
// pen/pencil/highlighter to the brush color; rz1.c(m4f,…) renders the rest.
// ToolGlyph composites the extracted fill/outline pathData under a Shape
// 24×24 viewPort scaled to the button; labels stay as accessibilityText.
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const glyphsPath = join(root, 'note/src/main/ets/ui/components/ToolGlyphs.ets');
const glyphPath = join(root, 'note/src/main/ets/ui/components/ToolGlyph.ets');
const toolbarPath = join(root, 'note/src/main/ets/ui/editor/EditorToolbar.ets');
const glyphs = readFileSync(glyphsPath, 'utf8');
const glyph = readFileSync(glyphPath, 'utf8');
const toolbar = readFileSync(toolbarPath, 'utf8');

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

// --- glyph registry covers every toolbox tool (ho5 set) ---
const KEYS = ['pen', 'pencil', 'highlighter', 'eraser', 'eraser_partial',
  'eraser_whole', 'selectrectangle', 'laser', 'zoom', 'tape', 'text'];
KEYS.forEach(k => eq(glyphs.includes(`'${k}':`), `glyph '${k}' present in TOOL_GLYPHS`));

// fill (f) / outline (o) pathData present for composite tools; single-icon
// tools carry the expected single layer.
['pen', 'pencil', 'highlighter', 'eraser', 'selectrectangle', 'laser', 'zoom', 'tape', 'text']
  .forEach(k => {
    const seg = glyphs.slice(glyphs.indexOf(`'${k}':`));
    eq(/f: `M/.test(seg), `'${k}' has a fill path (ui_designsystem__${k}_fill)`);
    eq(/o: `M/.test(seg), `'${k}' has an outline path (ui_designsystem__${k}_outline)`);
  });
eq(/'eraser_partial': \{ f: `M/.test(glyphs), 'eraser_partial is a fill-only single icon');
eq(/'eraser_whole': \{ f: ``, o: `M/.test(glyphs), 'eraser_whole is a stroke-only single icon');
eq(glyphs.split(/\n/).filter(l => /'[a-z_]+': \{/.test(l)).length === 11,
  'exactly 11 toolbox glyphs registered');

// --- ToolGlyph composites the layers deterministically (Shape+viewPort). ---
eq(/toolGlyphKey\(toolType: ToolType\)/.test(glyph), 'toolGlyphKey maps ToolType->glyph key');
['ToolType.PEN', 'ToolType.PENCIL', 'ToolType.HIGHLIGHTER', 'ToolType.SELECTION',
  'ToolType.LASER', 'ToolType.ZOOM', 'ToolType.REVIEW']
  .forEach(t => eq(glyph.includes(t), `toolGlyphKey handles ${t}`));
eq(/Shape\(\)/.test(glyph), 'ToolGlyph wraps layers in a Shape');
eq(/\.viewPort\(\{[^}]*width: 24,\s*height: 24/.test(glyph),
  'Shape viewPort is the original 24×24 icon space');
eq(/\.commands\(this\.paths\(\)\.f\)/.test(glyph), 'fill layer renders the f pathData');
eq(/\.commands\(this\.paths\(\)\.o\)/.test(glyph), 'outline layer renders the o pathData');
eq(glyph.includes('COLOR_GLYPHS') && /pen.*pencil.*highlighter/.test(glyph.replace(/\s/g, '')),
  'pen/pencil/highlighter fill tinted to brushColor (cq.h semantics)');
eq(glyph.includes('brushColor'), 'brushColor prop plumbed for color tools');
eq(glyph.includes('contentColor'), 'contentColor prop tints outline/foreground');

// --- EditorToolbar integrates the glyph buttons ---
eq(/import \{ ToolGlyph, toolGlyphKey \} from '\.\.\/components\/ToolGlyph'/.test(toolbar),
  'EditorToolbar imports ToolGlyph/toolGlyphKey');
eq(/StateToolButton\([^)]*\) \{\s*[\s\S]*?ToolGlyph/.test(toolbar),
  'StateToolButton renders a ToolGlyph icon (not a text label)');
eq(/toolGlyphKey\(tool\.toolType\)/.test(toolbar), 'tool button picks glyph from toolType');
eq(/brushColor: tool\.brush\.color/.test(toolbar), 'tool button passes brush.color');
eq(/accessibilityText\(label\)/.test(toolbar),
  'tool label preserved as accessibilityText (a11y unchanged)');
eq(/glyph: 'eraser_whole'/.test(toolbar), 'whole-eraser mode button uses eraser_whole glyph');
eq(/glyph: 'eraser_partial'/.test(toolbar), 'partial-eraser mode button uses eraser_partial glyph');
eq(!/StateToolButton[\s\S]{0,120}Button\(label\)/.test(toolbar),
  'no leftover Button(label) text button in StateToolButton');

console.log(`\neditor-toolbar-glyphs: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { console.log('FAILED:', fail); process.exit(1); }
