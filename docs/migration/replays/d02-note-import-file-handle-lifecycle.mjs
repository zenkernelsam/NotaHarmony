import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/NoteImporter.ets'), 'utf8').replaceAll('\r\n', '\n');
const importFromFileStart = source.indexOf('async importFromFile(context: common.UIAbilityContext)');
const importFromFileEnd = source.indexOf('// 我方格式导入', importFromFileStart);
const importNotabilityStart = source.indexOf('private async importNotability(');
const importNotabilityEnd = source.indexOf('private async mapImportedPageIds(', importNotabilityStart);
const importFromFile = source.slice(importFromFileStart, importFromFileEnd);
const importNotability = source.slice(importNotabilityStart, importNotabilityEnd);
const importFileFinallyCount = (importFromFile.match(/}\s*finally\s*{/g) ?? []).length;
const notabilityFinallyCount = (importNotability.match(/}\s*finally\s*{/g) ?? []).length;
const checks = [
  ['import function boundaries are found', importFromFileStart >= 0 && importFromFileEnd > importFromFileStart &&
    importNotabilityStart >= 0 && importNotabilityEnd > importNotabilityStart],
  ['import file has nullable ownership', importFromFile.includes('let file: fileIo.File | null = null;')],
  ['opened file is assigned to owned handle', importFromFile.includes('file = fileIo.openSync(uri')],
  ['successful close clears ownership', importFromFile.includes('fileIo.closeSync(file);\n      file = null;')],
  ['file finally closes failure handle', importFileFinallyCount === 1 &&
    importFromFile.includes('if (file !== null)') && importFromFile.includes('fileIo.closeSync(file);')],
  ['file ownership does not leak into Notability writer', !importNotability.includes('file !== null') &&
    !importNotability.includes('fileIo.closeSync(file)')],
  ['Notability writer retains one mutex finally', notabilityFinallyCount === 1 &&
    importNotability.includes('} finally {\n      release();\n    }')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
