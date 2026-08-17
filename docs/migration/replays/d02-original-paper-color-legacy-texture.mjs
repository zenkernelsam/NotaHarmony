import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

const root = new URL('../../../', import.meta.url);
const normalize = value => value.replace(/\r\n?/g, '\n');
const read = value => normalize(fs.readFileSync(new URL(value, root), 'utf8'));
const localPath = value => fileURLToPath(new URL(value, root));
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const original = name => normalize(
  fs.readFileSync(`${originalRoot}/sources/defpackage/${name}.java`, 'utf8'));
const sha256 = value => crypto.createHash('sha256').update(fs.readFileSync(value)).digest('hex');

const iq0 = original('iq0');
const n7j = original('n7j');
const htd = original('htd');
const o1 = original('o1');
const s3a = original('s3a');
const l3a = original('l3a');
const m3a = original('m3a');
const p4a = original('p4a');
const u3a = original('u3a');
const ua5 = original('ua5');

const picker = read('note/src/main/ets/core/model/OriginalTemplatePickerState.ets');
const colors = read('note/src/main/ets/core/model/OriginalPaperColor.ets');
const loader = read('note/src/main/ets/core/adaptation/OriginalPaperTextureLoader.ets');
const canvas = read('note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets');
const renderer = read('note/src/main/ets/rendering/PaperRenderer.ets');
const thumbnail = read('note/src/main/ets/rendering/ThumbnailRenderer.ets');
const noteCanvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const panel = read('note/src/main/ets/ui/components/PageSettingsPanel.ets');
const backgroundModel = read('note/src/main/ets/core/model/PageBackgroundModel.ets');
const fixture = read('note/src/test/OriginalPaperColor.test.ets');
const pickerFixture = read('note/src/test/OriginalTemplatePicker.test.ets');
const fixtureList = read('note/src/test/List.test.ets');

assert.match(iq0, /WHITE\(\(byte\) 13\)[\s\S]*CREAM\(\(byte\) 1\)[\s\S]*YELLOW\(\(byte\) 2\)[\s\S]*BLACK\(\(byte\) 15\)[\s\S]*BLUE\(\(byte\) 7\)[\s\S]*TAN\(\(byte\) 6\)/);
assert.match(n7j, /4294967295L[\s\S]*4294703348L[\s\S]*4294768335L[\s\S]*4280887593L[\s\S]*4292995308L[\s\S]*4293385652L/);
assert.match(s3a, /PaperInfo\(paperSize=[\s\S]*paperOrientation=[\s\S]*backgroundColor=[\s\S]*legacyPaperIndex=/);
assert.match(htd, /s3a\.a\(s3aVar, null, null, null, cmfVar, 3\)/);
assert.match(htd, /s3a\.a\(s3aVar2, null, null, Integer\.valueOf\(tu1\.b\(hu1VarA\)\), null, 3\)/);
assert.match(o1, /s3a\.a\(s3aVar3, null, null, null, cmfVar, 3\)/);
assert.match(o1, /s3a\.a\(s3aVar4, null, null, Integer\.valueOf\(tu1\.b\(hu1VarA\)\), null, 3\)/);
assert.match(l3a, /fag\.k\([\s\S]*num != null \? tu1\.c\(num\.intValue\(\)\) : null, s3aVar2\.d/);
assert.match(ua5, /rw1\.c\(qw3\.I, ix4Var, ru1Var, false/);
assert.equal((m3a.match(/R\.drawable\.core_paper__paper\d\d/g) ?? []).length, 15);
assert.match(m3a, /new cmf\(\(byte\) 8\)[\s\S]*new cmf\(\(byte\) 11\)[\s\S]*new cmf\(\(byte\) 12\)[\s\S]*new cmf\(\(byte\) 14\)[\s\S]*new cmf\(\(byte\) 15\)/);
assert.match(p4a, /ConcurrentHashMap/);
assert.match(u3a, /Invalid legacy paper index; no corresponding line color/);

assert.match(colors, /ORIGINAL_LEGACY_PAPER_PICKER_INDICES: number\[\] = \[13, 1, 2, 15, 7, 6\]/);
assert.match(colors, /case 13:[\s\S]*packOriginalArgb\(255, 255, 255\)/);
assert.match(colors, /case 15:[\s\S]*packOriginalArgb\(41, 41, 41\)/);
assert.equal((colors.match(/return 'core_paper__paper\d\d\.webp'/g) ?? []).length, 15);
assert.match(colors, /legacy === 8 \|\| legacy === 11 \|\| legacy === 12 \|\| legacy === 14 \|\| legacy === 15/);
assert.match(colors, /originalOpaqueArgbFromHsv[\s\S]*255\)/);
assert.match(colors, /background\.alpha !== 255[\s\S]*return null/);
assert.match(colors, /case '255,255,255': return opaque\(187, 187, 187\)/);
assert.match(colors, /explicit === null[\s\S]*red: 255, green: 255, blue: 255, alpha: 255/);
assert.match(colors, /invalid legacy index[\s\S]*return opaque\(0, 0, 0\)/);

assert.match(picker, /backgroundColor: packedPaperColor\(paper\)/);
assert.match(picker, /stageOriginalTemplateCustomColor[\s\S]*legacyPaperIndex: null/);
assert.match(picker, /stageOriginalTemplateLegacyPaper[\s\S]*backgroundColor: null/);
assert.match(picker, /target\.colorA = color\.alpha/);
assert.match(picker, /target\.legacyPaperIndex = draft\.legacyPaperIndex/);
assert.match(picker, /packedPaperColor\(paper\) !== draft\.backgroundColor/);

assert.match(panel, /ORIGINAL_LEGACY_PAPER_PICKER_INDICES/);
assert.match(panel, /stageOriginalTemplateLegacyPaper/);
assert.match(panel, /stageOriginalTemplateCustomColor/);
assert.match(panel, /Slider\(\{ value: this\.customHue, min: 0, max: 360/);
assert.match(panel, /Slider\(\{ value: this\.customSaturation, min: 0, max: 100/);
assert.match(panel, /Slider\(\{ value: this\.customValue, min: 0, max: 100/);
assert.match(panel, /templatePreviewBackground\(\)/);
assert.match(panel, /templatePreviewLineColor\(\)/);
assert.match(panel, /customColorExpanded = true;[\s\S]*if \(this\.draft\.backgroundColor === null\)[\s\S]*this\.stageCustomColor\(\)/);
assert.match(panel, /customColorCss\(\)[\s\S]*this\.draft\.backgroundColor !== null[\s\S]*originalArgbCssColor\(this\.draft\.backgroundColor\)/);

assert.match(loader, /getRawFileContent\(resourceName\)/);
assert.match(loader, /ORIGINAL_LEGACY_PAPER_TEXTURE_SIZE: number = 1024/);
assert.match(loader, /new ImageBitmap\(pixelMap\)/);
assert.match(loader, /loaded\.bitmap\.close\(\)/);
assert.match(canvas, /setFillPattern\(image: ImageBitmap[\s\S]*createPattern\(image, 'repeat'\)/);
assert.match(canvas, /setFilter\(filter: string\)/);
assert.match(renderer, /originalPaperRenderStyle/);
assert.match(renderer, /ctx\.setFillPattern\(legacyTexture\.bitmap/);
assert.match(renderer, /ctx\.setFilter\(style\.invertLegacyTexture \? 'invert\(1\)' : 'none'\)/);
assert.match(renderer, /fillRect\(0, 0, paperW, paperH\)[\s\S]*legacyTexture[\s\S]*drawPdfBackground[\s\S]*switch \(page\.template\)/);

assert.match(noteCanvas, /paperTextureGeneration/);
assert.match(noteCanvas, /pageGeneration !== this\.pageLoadGeneration/);
assert.match(noteCanvas, /generation !== this\.paperTextureGeneration/);
assert.match(noteCanvas, /releasePaperTexture\(\)/);
assert.match(thumbnail, /paperTextureLoader\.load/);
assert.match(thumbnail, /paperTextureLoader\.release\(paperTexture\)/);
assert.doesNotMatch(backgroundModel, /value\.colorA !== 255/);
assert.match(backgroundModel, /!isOptionalByte\(value\.colorA\)/);
assert.match(fixture, /keeps the original six legacy picker choices and all fifteen resources/);
assert.match(fixture, /keeps an existing translucent custom paper color/);
assert.match(fixture, /uses the original white default and invalid-legacy line fallbacks/);
assert.match(pickerFixture, /keeps color and legacy mutually exclusive for new picker actions/);
assert.match(fixtureList, /originalPaperColorTest\(\)/);

const copiedHashes = [];
for (let index = 1; index <= 15; index++) {
  const suffix = index.toString().padStart(2, '0');
  const name = `core_paper__paper${suffix}.webp`;
  const source = `${originalRoot}/resources/res/drawable/${name}`;
  const target = localPath(`note/src/main/resources/rawfile/${name}`);
  assert.ok(fs.existsSync(source), `missing original texture ${name}`);
  assert.ok(fs.existsSync(target), `missing ported texture ${name}`);
  const sourceHash = sha256(source);
  const targetHash = sha256(target);
  assert.equal(targetHash, sourceHash, `texture hash mismatch ${name}`);
  copiedHashes.push(targetHash);
}
assert.equal(new Set(copiedHashes).size, 15);

console.log('D02_ORIGINAL_PAPER_COLOR_LEGACY_TEXTURE_REPLAY_OK ' +
  'picker-order=13,1,2,15,7,6|draft-mutual-exclusion=1|hsv-no-alpha=1|' +
  'argb-alpha-preserved=1|legacy-assets=15|sha256-identical=15|repeat-pattern=1|' +
  'dark-inversion=1|default-line-fallback=1|custom-open-preserves-alpha=1|' +
  'canvas-generation-guard=1|thumbnail-release=1');
