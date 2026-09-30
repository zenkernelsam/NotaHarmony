// Phase 1297 — core infra (perf/log/network/copy-paste)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/core/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const np = R('analytics/NbPerformance$SpanAborted.java');
t('NbPerformance SpanAborted', np.includes('SpanAborted') && np.includes('Exception'));
const nl = R('common/logging/NbLog$FatalLogError.java');
t('NbLog FatalLogError Error', nl.includes('extends Error'));
const nc = R('network/NoConnectivityException.java');
t('NoConnectivity IOException', nc.includes('extends IOException') && nc.includes('No network connectivity'));
t('NotAuthenticatedException', X('network/NotAuthenticatedException.java'));
t('HttpStatusException', X('network/HttpStatusException.java'));
const hf = R('retrofit/HttpFailureException.java');
t('HttpFailureException status+msg', hf.includes('int I') && hf.includes('String J'));
const cp = R('model/CopyPasteException.java');
t('CopyPasteException sealed', cp.includes('CopyPasteException extends Exception'));
t('ConcurrentPaste subclass', cp.includes('ConcurrentPaste'));
t('Consistency subclass', cp.includes('Consistency'));
t('CopyPasteException extends Exception', cp.includes('abstract class CopyPasteException'));
console.log('core-infra replay: ' + n + '/10 checks green');
