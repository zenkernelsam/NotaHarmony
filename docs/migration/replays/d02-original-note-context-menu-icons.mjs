// Phase 1376 — library note-card context menu items carry their original
// d5j icons (MenuItem.startIcon -> media SVG replicas).
//
// d5j.java: each menu row is apb.f(icon=h1a, label). Mapping:
//   rename=ui_designsystem__edit  favorite/unfavorite=__favorite_outline/
//     __unfavorite_outline  duplicate=__duplicate  export=__export
//   show_in_folder=__show_in_folder  move_to_folder(sort_to_folder)=
//     __show_in_folder  copy_note_id=__note_info  delete=ue4.z()=__trash
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const lib = readFileSync(join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');
const seg = lib.slice(lib.indexOf('NoteContextMenu(note: NoteMeta)'),
  lib.indexOf('MoveNoteSubMenu(note: NoteMeta)'));

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

const ITEM = [
  ['rename', 'app.media.edit'],
  ['duplicate_note', 'app.media.selmenu_duplicate'],
  ['export_note', 'app.media.menuicon_export'],
  ['show_in_folder', 'app.media.menuicon_showfolder'],
  ['copy_note_id', 'app.media.menuicon_noteinfo'],
];
ITEM.forEach(([str, icon]) => {
  eq(new RegExp(`content: \\$r\\('app\\.string\\.${str}'\\), startIcon: \\$r\\('${icon.replace('.', '\\.')}'\\)`)
      .test(seg), `note menu '${str}' startIcon ${icon.split('.').pop()}`);
});
// favorite toggle -> favorite_outline / unfavorite_outline
eq(seg.includes("$r('app.media.menuicon_unfavorite')") &&
   seg.includes("$r('app.media.menuicon_favorite')"),
  'favorite/unfavorite toggles favorite/unfavorite_outline icons');
// move_to_folder -> show_in_folder icon (sort_to_folder reuse)
eq(seg.includes("content: $r('app.string.move_to_folder'),\n        startIcon: $r('app.media.menuicon_showfolder')"),
  'move_to_folder uses show_in_folder icon (sort_to_folder reuse)');
// delete -> trash (ue4.z)
eq(seg.includes("content: $r('app.string.delete'), startIcon: $r('app.media.selmenu_delete')"),
  'delete uses selmenu_delete (ui_designsystem__trash)');

// --- media resources exist ---
['menuicon_favorite','menuicon_unfavorite','menuicon_export','menuicon_showfolder',
 'menuicon_noteinfo','edit','selmenu_duplicate','selmenu_delete'].forEach(m => {
  eq(existsSync(join(root, `note/src/main/resources/base/media/${m}.svg`)),
     `media ${m}.svg present`);
});

// --- behavior unchanged ---
eq(seg.includes('this.toggleNoteFavorite(note)') &&
   seg.includes('this.duplicateNote(note)') &&
   seg.includes('this.exportNote(note)') &&
   seg.includes('note.folderId !== null') &&
   seg.includes('this.confirmDelete(note)'),
  'menu item actions/enabled state unchanged');

console.log(`\nnote-context-menu-icons: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { console.log('FAILED:', fail); process.exit(1); }
