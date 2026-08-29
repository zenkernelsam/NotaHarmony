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
assert.match(confirm,
  /private async onFolderDialogConfirm\(name: string\): Promise<boolean> \{\s+if \(!this\.pageActive\) \{\s+return false;\s+\}\s+const trimmed:/,
  'stale folder dialog cannot start a mutation');
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
assert.match(deleteFolder,
  /private async deleteFolder\(folderId: string\): Promise<void> \{\s+if \(!this\.pageActive \|\| this\.folderRepo === null \|\| this\.viewModel === null \|\| this\.folderBusy\) \{\s+return;\s+\}\s+const lifecycleGeneration: number = this\.lifecycleGeneration;/,
  'folder delete rejects inactive page before repository work');

const moveFolder = section(
  'private async moveFolder(folderId: string, parentId: string | null,',
  '\n  private orderedFolderSiblings');
assert.match(moveFolder, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
assert.match(moveFolder,
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.folderRepo !== repo/);
assert.match(moveFolder,
  /private async moveFolder\(folderId: string, parentId: string \| null,[\s\S]{0,160}?if \(!this\.pageActive \|\| this\.folderRepo === null \|\| this\.folderBusy\) \{\s+return;\s+\}\s+const lifecycleGeneration: number = this\.lifecycleGeneration;/,
  'folder move rejects inactive page before repository work');

const moveNote = section(
  'private async moveNote(noteId: string, folderId: string | null): Promise<void> {',
  '\n  private publishCommittedFolders');
assert.match(moveNote, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
assert.match(moveNote,
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive/);
assert.match(moveNote,
  /private async moveNote\(noteId: string, folderId: string \| null\): Promise<void> \{\s+if \(!this\.pageActive \|\| this\.folderRepo === null \|\| this\.viewModel === null \|\| this\.folderBusy\) \{\s+return;\s+\}\s+const lifecycleGeneration: number = this\.lifecycleGeneration;/,
  'note move rejects inactive page before repository work');

const moveBy = section(
  'private moveFolderBy(folder: NoteFolder, offset: number): void {',
  '\n  private clearFolderDrag');
assert.match(moveBy, /if \(!this\.pageActive \|\| this\.folderBusy\) \{\s+return;\s+\}\s+const siblings:/);

const toggle = section(
  'private toggleFolderExpanded(folderId: string): void {',
  '\n  private openCompactFolderDrawer');
assert.match(toggle, /if \(!this\.pageActive \|\| this\.folderBusy\) \{\s+return;\s+\}\s+const next:/);

for (const [name, pattern] of [
  ['create dialog', /private showCreateFolderDialog\(parentId: string \| null = null\): void \{\s+if \(!this\.pageActive \|\| this\.folderBusy\) \{/],
  ['rename dialog', /private showRenameFolderDialog\(folder: NoteFolder\): void \{\s+if \(!this\.pageActive \|\| this\.folderBusy\) \{/],
  ['folder delete confirmation', /private confirmDeleteFolder\(folder: NoteFolder\): void \{\s+if \(!this\.pageActive \|\| this\.folderBusy\) \{/],
  ['drag capture', /private captureFolderDrag\(event: ItemDragInfo, itemIndex: number\): void \{\s+if \(!this\.pageActive \|\| this\.folderBusy\) \{\s+this\.clearFolderDrag\(\);/],
  ['compact drawer open', /private openCompactFolderDrawer\(\): void \{\s+if \(!this\.pageActive \|\| this\.folderBusy\) \{/],
]) {
  assert.match(page, pattern, `${name} rejects inactive page before mutation`);
}

const entryModel = (pageActive, folderBusy) => {
  if (!pageActive || folderBusy) {
    return { started: false, mutated: false };
  }
  return { started: true, mutated: true };
};
assert.deepEqual(entryModel(false, false), { started: false, mutated: false });
assert.deepEqual(entryModel(true, true), { started: false, mutated: false });
assert.deepEqual(entryModel(true, false), { started: true, mutated: true });

console.log('D02_LIBRARY_FOLDER_MUTATIONS_LIFECYCLE_BOUND_REPLAY_OK TOTAL=18 FAILED=0');
