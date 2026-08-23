import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function section(startMarker, endMarker) {
  const start = page.indexOf(startMarker);
  const end = page.indexOf(endMarker, start + 1);
  assert.ok(start !== -1 && end > start, startMarker);
  return page.slice(start, end);
}

const confirm = section(
  'private async onFolderDialogConfirm(name: string): Promise<boolean> {',
  '\n  // 删除文件夹：内部笔记回根目录（不删笔记）');
assert.match(confirm, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
assert.match(confirm,
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.folderRepo !== repo/);

const deleteFolder = section(
  'private async deleteFolder(folderId: string): Promise<void> {',
  '\n  private async moveFolder(');
const deleteGuards = (deleteFolder.match(
  /lifecycleGeneration !== this\.lifecycleGeneration/g) ?? []).length;
assert.equal(deleteGuards >= 1, true);
assert.match(deleteFolder, /!this\.pageActive \|\|\s+this\.folderRepo !== repo/);

const moveFolder = section(
  'private async moveFolder(folderId: string, parentId: string | null,',
  '\n  private orderedFolderSiblings');
assert.match(moveFolder, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
assert.match(moveFolder,
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.folderRepo !== repo/);

const moveNote = section(
  'private async moveNote(noteId: string, folderId: string | null): Promise<void> {',
  '\n  private publishCommittedFolders');
assert.match(moveNote, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
assert.match(moveNote,
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive/);

console.log('D02_LIBRARY_FOLDER_MUTATIONS_LIFECYCLE_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
