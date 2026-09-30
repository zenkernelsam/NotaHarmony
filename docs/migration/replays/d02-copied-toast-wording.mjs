// Phase 1363 — copied-confirmation toast wording.
// Original feature_note__copied_link = "Copied Link" (Copied-X word order).
// Harmony had "Link copied" / "Note ID copied"; aligned to the original order.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const en = JSON.parse(readFileSync(join(root, 'note/src/main/resources/base/element/string.json'), 'utf8'));
const zh = JSON.parse(readFileSync(join(root, 'note/src/main/resources/zh_CN/element/string.json'), 'utf8'));
const get = (j, k) => (j.string.find(s => s.name === k) || {}).value;
const ncv = readFileSync(join(root, 'note/src/main/ets/ui/editor/NoteCanvasView.ets'), 'utf8');
const tbo = readFileSync(join(root, 'note/src/main/ets/ui/components/TextBlockOverlay.ets'), 'utf8');
const lib = readFileSync(join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

eq(get(en, 'link_copied') === 'Copied Link', 'link_copied=Copied Link (copied_link)');
eq(get(en, 'note_id_copied') === 'Copied note ID', 'note_id_copied=Copied note ID (Copied-X order)');
eq(get(zh, 'link_copied') === '已复制链接', 'zh link_copied kept');
eq(get(zh, 'note_id_copied') === '笔记 ID 已复制', 'zh note_id_copied kept');
eq(ncv.includes("showToast({ message: $r('app.string.link_copied')"), 'canvas link-copy toast uses link_copied');
eq(tbo.includes("showToast({ message: $r('app.string.link_copied')"), 'textblock link-copy toast uses link_copied');
eq(lib.includes("showToast({ message: $r('app.string.note_id_copied')"), 'library note-id toast uses note_id_copied');
eq(get(en, 'copy_note_id') === 'Copy note ID', 'copy_note_id action label held');
eq(get(en, 'new_note') === 'New Note', 'new_note speed-dial label held');
eq(get(en, 'record_audio') === 'Record', 'record_audio=Record held');

console.log(`copied-toast-wording: ${pass}/${pass + fail.length} checks green`);
if (fail.length) process.exitCode = 1;
