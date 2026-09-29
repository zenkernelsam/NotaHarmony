// Phase 1011 — 转写子系统 schema + ncf 段模型
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e47 = readFileSync(D + 'e47.java', 'utf8');
const ncf = readFileSync(D + 'ncf.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// transcriptions table
t('e47: transcriptions DDL core cols', e47.includes('`transcriptions`') && e47.includes('`sha512Hash` TEXT NOT NULL') && e47.includes('`processorVersion` REAL') && e47.includes('`serverCompletedAt` INTEGER'));
t('e47: sha512Hash UNIQUE index', e47.includes('index_transcriptions_sha512Hash') && e47.includes('UNIQUE'));
t('e47: 4 secondary indexes', e47.includes('index_transcriptions_recordingId') && e47.includes('index_transcriptions_noteId') && e47.includes('index_transcriptions_status') && e47.includes('index_transcriptions_createdAt'));
t('e47: status/language/fullText cols', e47.includes('`status` TEXT NOT NULL') && e47.includes('`language` TEXT') && e47.includes('`fullText` TEXT'));
// transcription_segments
t('e47: segments DDL', e47.includes('`transcription_segments`') && e47.includes('`transcriptionId` INTEGER NOT NULL'));
t('e47: FK CASCADE to transcriptions', e47.includes('FOREIGN KEY(`transcriptionId`) REFERENCES `transcriptions`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE'));
t('e47: segment cols text/start/end/confidence', e47.includes('`startTime` REAL NOT NULL') && e47.includes('`endTime` REAL NOT NULL') && e47.includes('`confidence` REAL NOT NULL'));
t('e47: segment indexes', e47.includes('index_transcription_segments_transcriptionId') && e47.includes('index_transcription_segments_startTime'));
// ncf model
t('ncf: {double,double,ucf,int}', /class ncf[\s\S]{0,80}public final double a;[\s\S]{0,40}public final double b;[\s\S]{0,40}public final ucf c;[\s\S]{0,40}public final int d;/.test(ncf));
t('ncf: copy ctor a(...)', /static ncf a\(ncf ncfVar, double d, double d2, int i, int i2\)/.test(ncf));
// separate DB
t('e47: TranscriptionDatabase_Impl import', e47.includes('TranscriptionDatabase_Impl'));
// search integration (RECORDING_TRANSCRIPT exists)
const me2 = readFileSync(D + 'me2.java', 'utf8');
t('me2: RECORDING_TRANSCRIPT type', me2.includes('"RECORDING_TRANSCRIPT"'));
console.log('transcription-schema replay: ' + n + '/12 checks green');
