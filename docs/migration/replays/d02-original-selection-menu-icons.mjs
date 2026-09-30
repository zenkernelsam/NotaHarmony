// Phase 1375 — selection context menu items carry their original
// ux9/r68 icons (MenuElement.icon -> media SVG replicas of the original
// selection_menu_*/ui_designsystem__* vectors).
//
// ux9.java: each r68 menu row wraps a drawable painter (n68/o68):
//   copy=ui_designsystem__copy  cut=__cut  duplicate=__duplicate
//   group/ungroup=__group  send_fwd/to_front=selection_menu_send_forward
//   send_bwd/to_back=selection_menu_send_backward  delete=ue4.z()=__trash
//   edit_math=selection_menu_convert_to_math  crop=selection_menu_crop
//   flip_h=selection_menu_flip_horizontal  flip_v=__flip_vertical
//   lock=__lock  unlock=__unlock  deselect=__circle_minus
//   style=selection_menu_style_outline  paste=__paste_content_manager
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const overlay = readFileSync(join(root, 'note/src/main/ets/ui/components/SelectionOverlay.ets'), 'utf8');
const read = (p) => readFileSync(join(root, p), 'utf8');

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

// --- each item carries the matching original icon ---
const MAP = [
  ['selection_style', 'selmenu_style'],
  ['copy', 'selmenu_copy'],
  ['cut', 'selmenu_cut'],
  ['duplicate_note', 'selmenu_duplicate'],
  ['paste', 'selmenu_paste'],
  ['bring_forward', 'selmenu_forward'],
  ['send_backward', 'selmenu_backward'],
  ['send_to_front', 'selmenu_forward'],
  ['send_to_back', 'selmenu_backward'],
  ['delete', 'selmenu_delete'],
  ['edit_math', 'selmenu_edit_math'],
  ['crop', 'selmenu_crop'],
  ['flip_horizontal', 'selmenu_flip_h'],
  ['flip_vertical', 'selmenu_flip_v'],
  ['deselect', 'selmenu_deselect'],
];
MAP.forEach(([str, icon]) => {
  const re = new RegExp(`value: \\$r\\('app\\.string\\.${str}'\\),?\\s*icon: \\$r\\('app\\.media\\.${icon}'\\)`);
  eq(re.test(overlay) ||
     overlay.includes(`value: $r('app.string.${str}'), icon: $r('app.media.${icon}')`),
     `menu item '${str}' uses ${icon}`);
});
// group/ungroup share selmenu_group; lock/unlock conditional.
eq(overlay.includes(`value: $r('app.string.group'), icon: $r('app.media.selmenu_group')`),
  'group uses selmenu_group');
eq(overlay.includes(`value: $r('app.string.ungroup'), icon: $r('app.media.selmenu_group')`),
  'ungroup shares selmenu_group (original reuse)');
eq(overlay.includes("this.positionLocked ? $r('app.media.selmenu_unlock') : $r('app.media.selmenu_lock')"),
  'lock/unlock toggles selmenu_lock/unlock');

// --- all referenced media resources exist on disk ---
['selmenu_style','selmenu_copy','selmenu_cut','selmenu_duplicate','selmenu_paste',
 'selmenu_group','selmenu_forward','selmenu_backward','selmenu_delete',
 'selmenu_edit_math','selmenu_crop','selmenu_flip_h','selmenu_flip_v',
 'selmenu_lock','selmenu_unlock','selmenu_deselect'].forEach(m => {
  eq(existsSync(join(root, `note/src/main/resources/base/media/${m}.svg`)),
     `media ${m}.svg present`);
});

// --- behavior unchanged: deselectMode confirm/cancel pair carries no icon ---
eq(overlay.includes("value: $r('app.string.done'), action: () => { this.onMenuAction(SelectionMenuAction.DESELECT_CONFIRM)"),
  'deselectMode done item unchanged (no icon — original k2f bar)');

console.log(`\nselection-menu-icons: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { console.log('FAILED:', fail); process.exit(1); }
