// Phase 1119 — core/ named exception taxonomy + package map
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const G = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/';
const R = p => readFileSync(G + p, 'utf8');
const http = R('core/network/HttpStatusException.java'),
      noconn = R('core/network/NoConnectivityException.java'),
      notauth = R('core/network/NotAuthenticatedException.java'),
      copypaste = R('core/model/CopyPasteException.java');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('HttpStatusException extends IOException', http.includes('extends IOException'));
t('HttpStatusException {int code, Strings}', http.includes('int I') && http.includes('String J'));
t('NoConnectivity extends IOException', noconn.includes('extends IOException'));
t('NoConnectivity msg', noconn.includes('No network connectivity'));
t('NotAuthenticatedException exists', notauth.length > 0 && notauth.includes('NotAuthenticated'));
t('CopyPaste sealed extends Exception', copypaste.includes('abstract class CopyPasteException extends Exception'));
t('CopyPaste: MissingPosition', copypaste.includes('MissingPosition'));
t('CopyPaste: IncompatibleContent', copypaste.includes('IncompatibleContent'));
t('CopyPaste: Consistency+InvalidArguments', copypaste.includes('Consistency') && copypaste.includes('InvalidArguments'));
t('CopyPaste: ConcurrentPaste data obj', copypaste.includes('ConcurrentPaste I = new ConcurrentPaste()'));
console.log('exception-taxonomy replay: ' + n + '/10 checks green');
