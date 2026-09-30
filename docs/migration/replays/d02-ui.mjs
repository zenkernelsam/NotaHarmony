// Phase 1166 — ui/fileimport PartialImport + ui/support Zendesk API
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/ui/';
const R = f => readFileSync(B + f, 'utf8');
const has = f => existsSync(B + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('PartialImportException exists', has('fileimport/data/importer/PartialImportException.java'));
t('PartialImportException extends Exception', R('fileimport/data/importer/PartialImportException.java').includes('extends Exception'));
t('PartialImportException(List,Throwable)', R('fileimport/data/importer/PartialImportException.java').includes('PartialImportException(List list, Throwable th)'));
t('support/data/ has ZendeskApiException', has('support/data/ZendeskApiException.java'));
t('support a = API iface', R('support/data/a.java').includes('interface a'));
t('support a suspend calls (ef2)', R('support/data/a.java').includes('ef2'));
t('support DTOs b..k present', has('support/data/b.java') && has('support/data/c.java') && has('support/data/e.java'));
t('support e DTO has ticketFormId+viaId', R('support/data/e.java').includes('ticketFormId') && R('support/data/e.java').includes('viaId'));
t('support c DTO {body,uploads}', R('support/data/c.java').includes('getBody') && R('support/data/c.java').includes('getUploads'));
t('support b DTO {results:List}', R('support/data/b.java').includes('getResults'));
console.log('ui replay: ' + n + '/10 checks green');
