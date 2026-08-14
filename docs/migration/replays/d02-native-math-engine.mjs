import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const native = fs.readFileSync(path.join(root, 'note/src/main/cpp/nota_math.cpp'), 'utf8');
const renderer = fs.readFileSync(path.join(root, 'note/src/main/ets/rendering/MathCanvasRenderer.ets'), 'utf8');
const engine = fs.readFileSync(path.join(root, 'note/src/main/ets/rendering/OriginalMathEngine.ets'), 'utf8');
const rawRoot = path.join(root, 'note/src/main/resources/rawfile/glmath');

const checks = [
  ['native parses with MicroTeX', native.includes('LaTeX::parse')],
  ['native uses Native Drawing bitmap', native.includes('OH_Drawing_BitmapBuild')],
  ['native enforces parser and bitmap budgets', native.includes('MAX_LATEX_BYTES') && native.includes('MAX_BITMAP_BYTES')],
  ['ArkTS extracts rawfile resources', engine.includes('getRawFileListSync') && engine.includes('getRawFileContentSync')],
  ['ArkTS publishes a versioned complete resource tree',
    engine.includes("const RESOURCE_VERSION: string = 'v1'") &&
      engine.includes("const COMPLETE_MARKER: string = '.complete'")],
  ['renderer composites bitmap and has no placeholder border', renderer.includes('drawImage') && !renderer.includes('setLineDash')],
  ['resource marker is packaged', fs.existsSync(path.join(rawRoot, '.clatexmath-res_root'))],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
