import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8').replaceAll('\r\n', '\n');

const start = page.indexOf('private async initData(expectedLifecycleGeneration: number = this.lifecycleGeneration): Promise<void> {');
const end = page.indexOf('private onSystemDarkChange(): void {', start);
assert.ok(start !== -1 && end > start, 'initData body');
const body = page.slice(start, end);

const preferencesAwaitIndex = body.indexOf('await preferences.getPreferences(context, THEME_PREFERENCES_NAME);');
assert.notEqual(preferencesAwaitIndex, -1, 'preferences await');
const firstGuardIndex = body.indexOf('renderer !== this.thumbRenderer', preferencesAwaitIndex);
const dbInitializeIndex = body.indexOf('await this.db.initialize(context);', firstGuardIndex);
assert.ok(firstGuardIndex > preferencesAwaitIndex && firstGuardIndex < dbInitializeIndex,
  'stale renderer cannot initialize the database');

const rendererCaptureIndex = body.indexOf('const renderer: ThumbnailRenderer = this.thumbRenderer;');
assert.notEqual(rendererCaptureIndex, -1, 'renderer capture');
const initializeIndex = body.indexOf('await renderer.initialize(context);', rendererCaptureIndex);
const secondGuardIndex = body.indexOf('renderer !== this.thumbRenderer', initializeIndex);
assert.ok(initializeIndex > rendererCaptureIndex && secondGuardIndex > initializeIndex,
  'fresh renderer initialization remains followed by an identity guard');

const reposPublishIndex = body.indexOf('this.noteRepo = noteRepo;', secondGuardIndex);
assert.ok(reposPublishIndex > secondGuardIndex, 'repositories publish only after current identity guard');

console.log('D02_LIBRARY_INIT_RENDERER_IDENTITY_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
