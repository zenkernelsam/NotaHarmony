// Phase 1171 — core/common memory(SharedMemoryByteArena)+logging(NbLog)+data/learn
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/';
const has = f => existsSync(B + f);
const R = f => readFileSync(B + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const mem = R('core/common/memory/a.java');
t('SharedMemoryByteArena exists (memory/a)', has('core/common/memory/a.java'));
t('uses android.os.SharedMemory', mem.includes('SharedMemory'));
t('SharedMemory.create + mapReadWrite', mem.includes('SharedMemory.create') && mem.includes('mapReadWrite'));
t('SharedMemory.unmap on close', mem.includes('SharedMemory.unmap'));
t('ArenaClosedException thrown', mem.includes('ArenaClosedException'));
t('ArenaClosedException class exists', has('core/common/memory/SharedMemoryByteArena$ArenaClosedException.java') && R('core/common/memory/SharedMemoryByteArena$ArenaClosedException.java').includes('IllegalStateException'));
t('bytes_allocated telemetry', mem.includes('bytes_allocated'));
const nb = R('core/common/logging/a.java');
t('NbLog impl exists', has('core/common/logging/a.java'));
t('NbLog FatalLogError extends Error', R('core/common/logging/NbLog$FatalLogError.java').includes('extends Error'));
t('data/learn LearnDatabase Room + AiDisabled', has('data/learn/database/LearnDatabase.java') && R('data/learn/database/LearnDatabase.java').includes('extends x5c') && R('data/learn/LearnError.java').includes('AiDisabled'));
console.log('common-memory replay: ' + n + '/10 checks green');
