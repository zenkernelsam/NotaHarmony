// Phase 1118 — core/ named package: root page-id + arena + model a/b
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const G = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = p => readFileSync(G + p, 'utf8');
const Rd = f => readFileSync(D + f + '.java', 'utf8');
const ma = R('core/model/a.java'), mb = R('core/model/b.java'),
      arena = R('core/common/memory/SharedMemoryByteArena$ArenaClosedException.java'),
      vex = R('core/flatbuffers/ValidationException.java'), c8d = Rd('c8d');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('model.a root pageId = nti.g(rh8.b(0,-1),0)', ma.includes('nti.g(rh8.b(0, -1), 0)'));
t('model.a {bs1,long,fqa,String,maps}', ma.includes('bs1 a') && ma.includes('fqa c') && ma.includes('LinkedHashMap'));
t('model.b materializer a(a79)→th7', mb.includes('th7 a(a79 a79Var)'));
t('model.b: m18.S() over a79.H bja', mb.includes('m18.S()') && mb.includes('a79Var.H'));
t('arena = SharedMemoryByteArena real name', arena.includes('SharedMemoryByteArena$ArenaClosedException'));
t('arena exc extends IllegalStateException', arena.includes('extends IllegalStateException'));
t('arena Kotlin @Metadata intact', arena.includes('@Metadata') && arena.includes('common'));
t('ValidationException named class', vex.includes('ValidationException'));
t('c8d = the arena impl (SharedMemory)', c8d.includes('SharedMemory') && c8d.includes('AutoCloseable'));
t('model.a opId sentinel rh8.b', ma.includes('rh8.b(0'));
console.log('named-core replay: ' + n + '/10 checks green');
