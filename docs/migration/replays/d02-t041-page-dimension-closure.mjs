import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = (path) => fs.readFileSync(path, 'utf8').replaceAll('\r\n', '\n');
const ddl = read('note/src/main/ets/data/DatabaseHelper.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const editor = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const thumbnails = read('note/src/main/ets/rendering/ThumbnailRenderer.ets');
const task = read('docs/migration/tasks/T-041-storage-page-dimension.md');

assert.match(ddl, /page_index INTEGER NOT NULL,/);
assert.match(ddl, /width_mm REAL NOT NULL DEFAULT 210\.0,/);
assert.match(ddl, /height_mm REAL NOT NULL DEFAULT 297\.0,/);
assert.match(ddl, /UNIQUE\(note_id, page_index\),/);
assert.match(ddl, /UNIQUE\(note_id, page_id\),/);

for (const source of [importer, editor, thumbnails, exporter]) {
  assert.match(source, /pageInfo\.pageId|targetPageId|page\.pageId|p\.pageId/);
  assert.ok(!source.includes('flattenPages'));
}

const ourStart = importer.indexOf('private async importOurFormat(');
const externalStart = importer.indexOf('private async importExternalFormat(');
assert.ok(ourStart !== -1 && externalStart > ourStart);
const our = importer.slice(ourStart, externalStart);
assert.match(our, /if \(page\.pageIndex !== i \|\| pageIds\.has\(page\.pageId\)\) \{\s+failedPages\+\+;\s+continue;/);
assert.match(our, /reserveNotePageElementIds\(noteElementIds, pageElementIds\)/);
assert.match(our, /await pageRepo\.addImportedPage\(note\.id, pageInfo\);/);
assert.match(our, /await this\.persistence\.saveElements\(\s+note\.id, pageInfo\.pageId, pageStrokes, pageTexts, pageElementOrder, pageShapes, pageImages,\s+pageMathBlocks\);/);
assert.ok(!our.includes('DELETE FROM client_op'));

const notabilityStart = importer.indexOf('private async importNotability(');
const mappingStart = importer.indexOf('private async mapImportedPageIds(');
assert.ok(notabilityStart !== -1 && mappingStart > notabilityStart);
const notability = importer.slice(notabilityStart, mappingStart);
assert.match(notability, /NotabilitySessionParser\.toPageElements\(session, DEFAULT_TARGET_PAGE_WIDTH_VP\)/);
assert.match(notability, /reserveNotePageElementIds\(noteElementIds, pageElementIds\)/);
assert.match(notability, /pageId: pageId, pageIndex: i,/);
assert.match(notability, /await this\.persistence\.saveElements\(note\.id, pageInfo\.pageId, pages\[i\]\.strokes, \[\],\s+pages\[i\]\.elementOrder, pages\[i\]\.shapes\);/);
assert.ok(!notability.includes('flattenPages'));

const save = persistence.slice(persistence.indexOf('  async saveElements('),
  persistence.indexOf('  async commitOriginalPartialErase(', 1700));
assert.match(save, /queueSaveElements\(noteId, pageId, strokes, textBlocks, elementOrder, shapes,\s+false, undefined, images, mathBlocks\);/);
assert.match(persistence, /async loadElements\(noteId: string, pageId: string\): Promise<LoadedElements> \{/);
assert.doesNotMatch(persistence, /DELETE FROM client_op WHERE note_id = \?/);

assert.match(editor, /const loaded = await this\.persistence\.loadElements\(this\.noteId, targetPageId\);/);
assert.equal([...editor.matchAll(/persistence\.loadElements\(this\.noteId, targetPageId\)/g)].length >= 2, true);
assert.match(thumbnails, /await persistence\.loadElements\(noteId, page\.pageId\);/);
assert.match(exporter, /const loaded = await this\.persistence\.loadElements\(noteId, p\.pageId\);/);
assert.match(task, /# T-041 存储层页维度修复（多页导入丢失 bug）/);

console.log('D02_T041_PAGE_DIMENSION_CLOSURE_REPLAY_OK TOTAL=18 FAILED=0');
