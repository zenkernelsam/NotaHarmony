// Phase 1305 — Socket.IO + OTel + Metro DI + TIFF
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('Socket.IO client', existsSync(S + 'io/socket/client/SocketIOException.java'));
t('Engine.IO', existsSync(S + 'io/socket/engineio/client/EngineIOException.java'));
t('socket parser', existsSync(S + 'io/socket/parser/DecodingException.java'));
t('opentelemetry', existsSync(S + 'io/opentelemetry'));
t('otel disk buffering', existsSync(S + 'io/opentelemetry/contrib/disk/buffering'));
t('metro DI', existsSync(S + 'dev/zacsweers/metrox/android/MetroAppComponentFactory.java'));
t('TiffBitmapFactory', existsSync(S + 'org/beyka/tiffbitmapfactory/TiffBitmapFactory.java'));
t('TiffBitmapFactory progress', existsSync(S + 'org/beyka/tiffbitmapfactory/IProgressListener.java'));
t('caverock AndroidSVG', existsSync(S + 'com/caverock'));
t('fasterxml jackson', existsSync(S + 'com/fasterxml/jackson'));
console.log('realtime-otel-metro replay: ' + n + '/10 checks green');
