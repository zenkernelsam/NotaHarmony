// Phase 1016 — WorkManager vendored schema + app worker roster
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e47 = readFileSync(D + 'e47.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('WorkSpec: ~30-col spec', e47.includes('`WorkSpec`') && e47.includes('`worker_class_name`') && e47.includes('`next_schedule_time_override`') && e47.includes('`backoff_on_system_interruptions`'));
t('WorkSpec: constraints cols', e47.includes('`required_network_type`') && e47.includes('`requires_charging`') && e47.includes('`content_uri_triggers`'));
t('WorkTag: (tag,ws) PK', e47.includes('`WorkTag`') && e47.includes('PRIMARY KEY(`tag`, `work_spec_id`)'));
t('WorkName: (name,ws) PK', e47.includes('`WorkName`') && e47.includes('PRIMARY KEY(`name`, `work_spec_id`)'));
t('WorkProgress: ws PK + blob', e47.includes('`WorkProgress`') && e47.includes('`progress` BLOB'));
t('SystemIdInfo: (ws,generation)', e47.includes('`SystemIdInfo`') && e47.includes('PRIMARY KEY(`work_spec_id`, `generation`)'));
t('Dependency: (ws,prereq)', e47.includes('`Dependency`') && e47.includes('PRIMARY KEY(`work_spec_id`, `prerequisite_id`)'));
// workers (4 app worker classes carry their name string)
const cb9 = readFileSync(D + 'cb9.java', 'utf8');
const fjg = readFileSync(D + 'fjg.java', 'utf8');
const f64 = readFileSync(D + 'f64.java', 'utf8');
const eoh = readFileSync(D + 'eoh.java', 'utf8');
t('NoteOpsUpdaterWorker tag', cb9.includes('NoteOpsUpdaterWorker'));
t('Extraction+Sweep+Pack workers', fjg.includes('ExtractionWorker') && f64.includes('ExportSweepWorker') && eoh.includes('HandwritingPackDownloadWorker'));
console.log('workmanager-schema replay: ' + n + '/9 checks green');
