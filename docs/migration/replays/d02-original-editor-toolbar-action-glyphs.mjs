// Phase 1370 — editor toolbar action buttons render original
// ui_designsystem__* vector glyphs instead of unicode placeholders.
//
// Mapping (decompiled_1.0.3):
//   ▦ pages/content-manager toggle → ui_designsystem__content_manager
//     (fp0.java p2c RichIcon: fill + overlay + outline_default/selected)
//   ... compact overflow          → ui_designsystem__hamburger (ke1.java go5.b)
//   ⚙ toolbox settings            → ui_designsystem__settings_* layered m4f
//     (ho5.u via rz1.c — same five-layer pipeline as the tool glyphs)
//   ↶ undo                        → ui_designsystem__topnavundo (p9f.java)
//   ↷ redo                        → ui_designsystem__topnavredo (p9f.java)
//   ↗ share                       → ui_designsystem__share (ke1.java go5.b)
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const glyphsPath = join(root, 'note/src/main/ets/ui/components/ToolGlyphs.ets');
const toolbarPath = join(root, 'note/src/main/ets/ui/editor/EditorToolbar.ets');
const glyphs = readFileSync(glyphsPath, 'utf8');
const toolbar = readFileSync(toolbarPath, 'utf8');

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

// --- action glyph keys registered in TOOL_GLYPHS ---
const ACTION = ['topnavundo', 'topnavredo', 'share', 'hamburger',
  'settings', 'content_manager', 'content_manager_selected'];
ACTION.forEach(k => eq(glyphs.includes(`'${k}':`), `action glyph '${k}' registered`));

// Flat single-tint icons carry their vector in the outline (o) slot, no fill.
// topnavundo/topnavredo/share/hamburger are go5.b ColorFilter single-tint icons.
['topnavundo', 'topnavredo', 'share', 'hamburger']
  .forEach(k => {
    const seg = glyphs.slice(glyphs.indexOf(`'${k}':`));
    eq(/o: `M/.test(seg), `'${k}' carries its vector pathData (single-tint icon)`);
  });

// settings is a layered ho5.u m4f — fill + outline + highlight + shadow.
{
  const seg = glyphs.slice(glyphs.indexOf(`'settings':`));
  eq(/f: `M/.test(seg), 'settings has a fill path (settings_fill)');
  eq(/o: `M/.test(seg), 'settings has an outline path (settings_outline)');
  eq(/h: `M/.test(seg), 'settings has a highlight layer (settings_highlight)');
  eq(/s: `M/.test(seg), 'settings has a shadow layer (settings_shadow)');
}

// content_manager is a p2c RichIcon — fill + overlay + default/selected outline.
{
  const seg = glyphs.slice(glyphs.indexOf(`'content_manager':`));
  eq(/f: `M/.test(seg), 'content_manager has a fill path (content_manager_fill)');
  eq(/o: `M/.test(seg), 'content_manager has the default outline');
  const sel = glyphs.slice(glyphs.indexOf(`'content_manager_selected':`));
  eq(/o: `M/.test(sel), 'content_manager_selected carries the selected outline variant');
}

// --- EditorToolbar wires each action button to its glyph ---
// Phase 1396：outline_default/selected 随 pagesPanelOpen 切换（fp0 双轮廓）。
eq(/glyph: this\.pagesPanelOpen \? 'content_manager_selected' : 'content_manager'/.test(toolbar),
  'pages-panel toggle uses content_manager glyph family (replaces ▦)');
eq(/glyph: 'hamburger'/.test(toolbar),
  'compact overflow uses hamburger glyph (replaces ...)');
eq(/glyph: 'settings'/.test(toolbar),
  'settings button uses settings glyph (replaces ⚙)');
eq(/glyph: 'topnavundo'/.test(toolbar), 'undo button uses topnavundo glyph (replaces ↶)');
eq(/glyph: 'topnavredo'/.test(toolbar), 'redo button uses topnavredo glyph (replaces ↷)');
eq(/glyph: 'share'/.test(toolbar), 'share button uses share glyph (replaces ↗)');

// No unicode placeholder buttons remain in the toolbar.
['▦', '⚙', '↶', '↷', '↗'].forEach(ch =>
  eq(!toolbar.includes(`Button('${ch}')`), `no leftover Button('${ch}') placeholder`));
eq(!/Button\('\.\.\.'\)/.test(toolbar), `no leftover Button('...') placeholder`);

// --- behavior & accessibility preserved ---
eq(/accessibilityText\(\$r\('app\.string\.cd_pages_panel_toggle'\)\)/.test(toolbar),
  'pages-panel toggle keeps cd_pages_panel_toggle a11y');
eq(/accessibilityText\(\$r\('app\.string\.toolbar_more_menu'\)\)/.test(toolbar),
  'compact overflow keeps toolbar_more_menu a11y');
eq(/accessibilityText\(\$r\('app\.string\.toolbox_settings'\)\)/.test(toolbar),
  'settings keeps toolbox_settings a11y');
eq(/accessibilityText\(\$r\('app\.string\.cd_undo_action'\)\)/.test(toolbar),
  'undo keeps cd_undo_action a11y');
eq(/accessibilityText\(\$r\('app\.string\.cd_redo_action'\)\)/.test(toolbar),
  'redo keeps cd_redo_action a11y');
eq(/accessibilityText\(\$r\('app\.string\.cd_share_action'\)\)/.test(toolbar),
  'share keeps cd_share_action a11y');
eq(/bindMenu\(this\.buildCompactToolMenu\(\)\)/.test(toolbar),
  'compact overflow still binds the tool menu');
eq(/enabled\(this\.canUndo/.test(toolbar), 'undo keeps canUndo enabled gating');
eq(/enabled\(this\.canRedo/.test(toolbar), 'redo keeps canRedo enabled gating');
eq(/onTogglePagesPanel\(\)/.test(toolbar), 'pages toggle still calls onTogglePagesPanel');
eq(/showShareSheet = true/.test(toolbar), 'share still opens the share sheet');

console.log(`\neditor-toolbar-action-glyphs: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { console.log('FAILED:', fail); process.exit(1); }
