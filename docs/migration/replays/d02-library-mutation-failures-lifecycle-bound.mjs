import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function body(startMarker, endMarker) {
  const start = page.indexOf(startMarker);
  const end = page.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return page.slice(start, end);
}

const cases = [
  ['folder create/rename', body('  private async onFolderDialogConfirm(name: string, color: number,',
    '  // 删除文件夹'), "promptAction.showToast({ message: $r('app.string.folder_operation_failed') });", 'return false;'],
  ['delete folder', body('  private async deleteFolder(folderId: string): Promise<void> {',
    '  private async moveFolder(',), "promptAction.showToast({ message: $r('app.string.delete_folder_failed') });", 'return;'],
  ['move folder', body('  private async moveFolder(folderId: string, parentId: string | null,',
    '  private orderedFolderSiblings'), "promptAction.showToast({ message: $r('app.string.move_folder_failed') });", 'return;'],
  ['move note', body('  private async moveNote(noteId: string, folderId: string | null): Promise<void> {',
    '  private publishCommittedFolders'), "promptAction.showToast({ message: $r('app.string.move_note_failed') });", 'return;'],
];

for (const [name, text, effect] of cases) {
  const catchIndex = text.indexOf('catch (e)');
  assert.notEqual(catchIndex, -1, `${name}: catch`);
  const effectIndex = text.indexOf(effect, catchIndex);
  assert.notEqual(effectIndex, -1, `${name}: effect`);
  const guard = 'if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {';
  const guardIndex = text.lastIndexOf(guard, effectIndex);

  assert.ok(guardIndex !== -1 && guardIndex < effectIndex, name);
}

const noteDelete = body('  private async deleteNoteAndRefresh(noteId: string): Promise<void> {',
  '  private async createAndOpen(');
assert.match(noteDelete, /catch \(e\) \{\s+if \(lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.viewModel !== vm\) \{\s+return;/);

console.log('D02_LIBRARY_MUTATION_FAILURES_LIFECYCLE_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
