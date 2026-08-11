import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const loader = read('note/src/main/ets/core/adaptation/OriginalRecordingAssetLoader.ets');
const tests = read('note/src/test/OriginalRecordingAssetLoader.test.ets');
const list = read('note/src/test/List.test.ets');
const adr = read('docs/migration/adr/ADR-0066-original-recording-local-asset-loader.md');

assert.match(loader, /recordingOpenPrecondition\(recording\)/);
assert.match(loader, /fileIo\.openSync\(recording\.localPath as string, fileIo\.OpenMode\.READ_ONLY\)/);
assert.match(loader, /fileIo\.statSync\(file\.fd\)/);
assert.match(loader, /stat\.isFile\(\)/);
assert.match(loader, /actual !== expected/);
assert.match(loader, /descriptor = \{ fd: file\.fd, offset: 0, length: length \}/);
assert.match(loader, /fileIo\.closeSync\(file\)/);
assert.match(tests, /OriginalRecordingAssetState\.PENDING/);
assert.match(tests, /path is not a regular file/);
assert.match(tests, /file size does not match metadata/);
assert.match(list, /originalRecordingAssetLoaderTest\(\)/);
assert.match(adr, /reset or release the player/);
assert.doesNotMatch(loader, /createAVPlayer\(/);

console.log('recordingAsset=fd-lease-open-stat-exact-size');
