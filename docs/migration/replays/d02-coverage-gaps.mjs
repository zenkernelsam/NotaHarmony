// Phase 1307 — Harmony coverage-gap analysis (implemented vs deferred)
import { existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/';
const X = f => existsSync(S + f);
const find = (dir, pat) => { const r=[]; const w=x=>{try{for(const e of readdirSync(S+x,{withFileTypes:true})){const p=x+'/'+e.name; if(e.isDirectory())w(p);else if(pat.test(e.name))r.push(p);}}catch(_){}}; w(dir); return r; };
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// implemented
t('CRDT op codec', X('data/BinaryOpCodec.ets'));
t('recording impl', find('core/adaptation',/OriginalRecording.*Backend/).length > 0);
t('handwriting provider policy', X('core/adaptation/OriginalHandwritingProviderCapabilityPolicy.ets'));
t('search index types', X('data/SearchIndexPolicy.ets'));
// gaps
const billing = find('.',/billing|subscription|iap|purchase/i);
t('no billing impl (gap)', billing.length === 0);
const login = find('.',/^.*(oauth|signin|login)\.ets$/i);
t('no oauth login impl (gap)', login.length === 0);
const transcri = find('.',/transcription|liveTranscri/i);
t('no live-transcription module (gap)', transcri.length === 0);
t('recording backends present', find('core/adaptation',/OriginalRecording(Microphone|InternalAudio)Backend/).length >= 2);
t('recognition provider', X('core/adaptation/RecognitionProvider.ets'));
t('editor present', X('ui/editor/NoteCanvasView.ets'));
console.log('coverage-gaps replay: ' + n + '/10 checks green');
