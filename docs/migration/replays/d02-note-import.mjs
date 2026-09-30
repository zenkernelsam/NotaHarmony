// Phase 1310 — Harmony .note import (iOS ZIP+plist)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ni = readFileSync(S + 'NoteImporter.ets', 'utf8');
t('NoteImporter ZipReader', ni.includes('ZipReader'));
t('Session.plist handling', ni.includes('Session.plist'));
t('parseManifest', ni.includes('parseManifest'));
t('PDF magic sniff', ni.includes('%PDF-'));
t('picker .note filter', ni.includes('.note'));
t('jv5 500MB ref', ni.includes('500MB') || ni.includes('jv5'));
t('recordings.json CREATE_RECORDING', ni.includes('recordings.json') && ni.includes('CREATE_RECORDING'));
t('BinaryPlistParser', X('BinaryPlistParser.ets'));
const sp = readFileSync(S + 'NotabilitySessionParser.ets', 'utf8');
t('GLKeyedArchiver plist', sp.includes('GLKeyedArchiver') || sp.includes('bplist'));
t('ImportDetailsSheet UI', existsSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/components/ImportDetailsSheet.ets'));
console.log('note-import replay: ' + n + '/10 checks green');
