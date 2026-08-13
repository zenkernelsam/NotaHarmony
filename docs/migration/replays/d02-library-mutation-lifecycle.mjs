import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const page = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');
const viewModel = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/library/LibraryViewModel.ets'), 'utf8');

const createAction = page.slice(page.indexOf('private async createAndOpen'),
  page.indexOf('private applyBreakpoints'));
const deleteAction = page.slice(page.indexOf('private async deleteNoteAndRefresh'),
  page.indexOf('private async createAndOpen'));
const disappear = page.slice(page.indexOf('aboutToDisappear'), page.indexOf('onPageShow'));
const retire = page.slice(page.indexOf('private async retireThumbnailRenderer'),
  page.indexOf('private async refreshThumbnailGeneration'));
const thumbnail = page.slice(page.indexOf('private async refreshThumbnails'),
  page.indexOf('private onAssetAvailabilityChanged'));

const checks = [
  ['create commit catch ends before navigation',
    createAction.indexOf('create_note_failed') < createAction.indexOf('router.pushUrl')],
  ['navigation has an independent committed-create message', createAction.includes('created_note_open_failed')],
  ['delete thumbnail refresh is outside the mutation catch',
    deleteAction.indexOf('delete_note_failed') < deleteAction.indexOf('delete note thumbnail refresh failed')],
  ['disappear invalidates the lifecycle before renderer retirement',
    disappear.indexOf('this.lifecycleGeneration++') < disappear.indexOf('this.retireThumbnailRenderer(renderer)')],
  ['renderer retirement waits on the thumbnail mutex',
    retire.includes('await this.thumbnailRefreshMutex.lock()') && retire.includes('await renderer.dispose()')],
  ['one renderer is captured for each thumbnail generation',
    thumbnail.includes('const renderer: ThumbnailRenderer = this.thumbRenderer') &&
    thumbnail.includes('renderer.renderThumbnail(')],
  ['thumbnail publish is lifecycle bound',
    thumbnail.includes('lifecycleGeneration !== this.lifecycleGeneration')],
  ['page activation restores the asset subscription',
    page.includes('private activatePage(): number') &&
    page.includes('this.assetAvailabilitySubscription = assetAvailabilityHub.subscribe') &&
    /onPageShow\(\): void \{\s*const lifecycleGeneration: number = this\.activatePage\(\)/.test(page)],
  ['database mutations publish deterministic snapshots',
    viewModel.includes('next.push(note)') && viewModel.includes('this.removeVisibleNote(noteId)')],
  ['committed mutations invalidate stale reads',
    viewModel.includes('private mutationGeneration: number = 0') &&
    viewModel.includes('mutationGeneration !== this.mutationGeneration')],
];

for (const [name, ok] of checks) {
  assert.ok(ok, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
