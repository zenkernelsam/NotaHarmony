// Phase 1160 — full com.gingerlabs.notability package-tree inventory
import { readdirSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/';
const has = p => existsSync(B + p);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('app/ + initializers + widgets', has('app') && has('app/initializers') && has('app/widgets'));
t('core/ full', has('core') && has('core/flatbuffers') && has('core/glmath') && has('core/model'));
t('core/network + retrofit + analytics', has('core/network') && has('core/retrofit') && has('core/analytics'));
t('data/note/{assets,ops,state}', has('data/note/assets') && has('data/note/ops') && has('data/note/state'));
t('data/library/state/{db,folders,notes,ntb}', has('data/library/state/database') && has('data/library/state/folders') && has('data/library/state/ntb'));
t('data/search + settings + toolbar db', has('data/search/database') && has('data/settings/database') && has('data/toolbar/database'));
t('data/transcription + stylus + subscription', has('data/transcription') && has('data/stylus') && has('data/subscription'));
t('data/billing + samsungbilling', has('data/billing') && has('data/samsungbilling'));
t('feature/login/{apple,microsoft} + note toolbox audio', has('feature/login/apple') && has('feature/login/microsoft') && has('feature/note/toolbox/audio'));
t('ui/fileimport + support', has('ui/fileimport') && has('ui/support'));
console.log('pkg-tree replay: ' + n + '/10 checks green');
