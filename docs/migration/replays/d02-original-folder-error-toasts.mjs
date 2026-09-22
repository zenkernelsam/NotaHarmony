import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const repo = read('note/src/main/ets/data/FolderRepositoryImpl.ets');
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const sad = readOriginal('decompiled_1.0.3/sources/defpackage/sad.java');
const xdb = readOriginal('decompiled_1.0.3/sources/defpackage/xdb.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// sad: MaxFolderDepthExceededException -> vad.i -> qad case 1 emits the
// feature_library__error_max_folder_depth string; InvalidFolderNameException ->
// qad emits ui_folder__name_error_message.
ok(sad.includes('MaxFolderDepthExceededException') && sad.includes('vad.i(vadVar)') &&
   sad.includes('InvalidFolderNameException'),
  'original sad catch dispatch missing');
ok(xdb.includes('throw new MaxFolderDepthExceededException') &&
   xdb.includes('.getDepth()'),
  'original xdb subtree-depth rule missing');
ok(origStrings.includes('error_max_folder_depth">Notability is limited to 6 levels of folders.'),
  'original depth-limit message missing');
ok(origStrings.includes('ui_folder__name_error_message">A folder already exists with this name'),
  'original name-error message missing');

// --- Harmony anchors ----------------------------------------------------------------------
ok(repo.includes('export class MaxFolderDepthExceededError extends Error') &&
   repo.includes('export class InvalidFolderNameError extends Error'),
  'typed folder errors missing');
ok((repo.match(/throw new MaxFolderDepthExceededError/g) ?? []).length === 2,
  'depth throws must cover createFolder and validateFolderMove');
ok((repo.match(/throw new InvalidFolderNameError/g) ?? []).length === 2,
  'name throws must cover invalid and duplicate sibling names');
ok(repo.includes('MAX_FOLDER_DEPTH: number = ORIGINAL_MAX_FOLDER_DEPTH'),
  'original 6-level cap constant missing');
ok(page.includes('MaxFolderDepthExceededError') && page.includes('InvalidFolderNameError') &&
   page.includes('folderErrorToastRes'),
  'page error-toast mapping missing');
ok(page.includes("$r('app.string.error_max_folder_depth')") &&
   page.includes("$r('app.string.folder_name_error')"),
  'original message resources unused');
// All three catch surfaces route through the mapper.
ok((page.match(/this\.folderErrorToastRes\(e as Error/g) ?? []).length === 3,
  'catch sites must all map typed errors');
ok(stringsBase.includes('"name": "error_max_folder_depth"') &&
   stringsBase.includes('Notability is limited to 6 levels of folders.') &&
   stringsZh.includes('"name": "error_max_folder_depth"') &&
   stringsZh.includes('"name": "folder_name_error"'),
  'localized strings missing');

// --- Executable behaviour model -----------------------------------------------------------
const MAX = 6;
const subtreeHeight = h => h;
const canCreate = parentDepth => parentDepth + 1 <= MAX;
const canMove = (movedSubtreeDeepest, movedDepth, newParentDepth) =>
  (movedSubtreeDeepest - movedDepth) + newParentDepth + 1 <= MAX;
assert.ok(canCreate(5) && !canCreate(6));
assert.ok(canMove(2, 1, 4) && !canMove(4, 1, 4));
checks += 2;

console.log(`D02_ORIGINAL_FOLDER_ERROR_TOASTS_OK TOTAL=${checks} FAILED=0`);
