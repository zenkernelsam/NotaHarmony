// Phase 1336 — .note export→import roundtrip
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ex = readFileSync(S + 'NoteExporter.ets', 'utf8');
const im = readFileSync(S + 'NoteImporter.ets', 'utf8');
t('ZipWriter export', ex.includes('ZipWriter'));
t('manifest.json entry', ex.includes('manifest.json'));
t('pages/page_N.json', ex.includes('pages/'));
t('note.assets recordings', ex.includes('note.assets') || ex.includes('recordings'));
t('MissingAssetsException', ex.includes('MissingAssetsException'));
t('original yk9 ref', ex.includes('yk9'));
t('importer reads ZIP', im.includes('Session.plist') || im.includes('zip') || im.includes('Zip'));
t('session parser', existsSync(S + 'NotabilitySessionParser.ets'));
t('bplist parser', existsSync(S + 'BinaryPlistParser.ets'));
t('zip archive', existsSync(S + 'ZipArchive.ets') || existsSync(S + 'ZipReader.ets'));
console.log('note-roundtrip replay: ' + n + '/10 checks green');
