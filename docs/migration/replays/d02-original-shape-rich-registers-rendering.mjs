import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const readRepo = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');
const readOriginal = name => fs.readFileSync(path.join(originalRoot, name), 'utf8');

const ao2 = readOriginal('ao2.java');
const le8 = readOriginal('le8.java');
const k16 = readOriginal('k16.java');
const p16 = readOriginal('p16.java');
const y4d = readOriginal('y4d.java');
const xai = readOriginal('xai.java');

const model = readRepo('note/src/main/ets/core/model/ElementTypes.ets');
const geometry = readRepo('note/src/main/ets/core/model/ShapeGeometry.ets');
const strokeGeometry = readRepo('note/src/main/ets/core/model/ShapeStrokeGeometry.ets');
const recognition = readRepo('note/src/main/ets/core/model/ShapeRecognition.ets');
const encoder = readRepo('note/src/main/ets/data/OriginalCreateShapePayloadEncoder.ets');
const reducer = readRepo('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const persistence = readRepo('note/src/main/ets/data/StrokePersistence.ets');
const packageSpec = readRepo('note/src/main/ets/data/NotePackageSpec.ets');
const clipboard = readRepo('note/src/main/ets/rendering/StrokeClipboard.ets');
const partialEraser = readRepo('note/src/main/ets/rendering/OriginalShapePartialEraser.ets');
const renderer = readRepo('note/src/main/ets/rendering/ShapeCanvasRenderer.ets');
const thumbnail = readRepo('note/src/main/ets/rendering/ThumbnailRenderer.ets');
const canvas = readRepo('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const payloadFixture = readRepo('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');
const packageFixture = readRepo('note/src/test/NotePackageSpec.test.ets');
const clipboardFixture = readRepo('note/src/test/StrokeClipboard.test.ets');
const eraserFixture = readRepo('note/src/test/OriginalShapePartialEraser.test.ets');
const persistenceFixture = readRepo('note/src/test/StrokePersistence.test.ets');
const rendererFixture = readRepo('note/src/test/ShapeStrokeRenderer.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');

const modifyStart = reducer.indexOf('private async applyModifyShape');
const modifyEnd = reducer.indexOf('private async applyModifyGroup', modifyStart);
assert.ok(modifyStart >= 0 && modifyEnd > modifyStart, 'cannot isolate applyModifyShape');
const modifyShape = reducer.slice(modifyStart, modifyEnd);
const applyRegistersAt = modifyShape.indexOf('applyShapeRegisters(state, payload, operation)');
const validateResolvedAt = modifyShape.indexOf('validateCreateShape(state.resolved, null)');
const journalAt = modifyShape.indexOf("await store.insert('original_shape_modification'");

const checks = [
  ['original CreateShape rejects variable width and transparent fill',
    ao2.includes('Cannot create shapes with variable width ink') &&
      ao2.includes('Do not use zero alpha')],
  ['original CreateShape validates tint and effect-tool coupling',
    ao2.includes('ink_effects_tinted is only meaningful with non-zero ink_effects') &&
      ao2.includes('ink_effects require a Pen or Highlighter tool')],
  ['Shape TapePattern remains an independent register rather than a CreateInk restriction',
    ao2.includes(', tapePattern=') &&
      !ao2.includes('Cannot specify a TapePattern while Tool is not Tape')],
  ['original ModifyShape keeps independent Tape/effect/tint registers',
    le8.includes(', tapePattern=') && le8.includes(', inkEffects=') &&
      le8.includes(', inkEffectsTinted=')],
  ['original ShapeDefinition uses native line verbs oval and closed polygon',
    xai.includes('path.cubicTo(') && xai.includes('path.quadTo(') &&
      xai.includes('path.lineTo(') && xai.includes('path2.addOval(') &&
      xai.includes('path3.close()')],
  ['original Pencil Shape has a separate renderer branch',
    k16.includes('n5dVar.Y() == u16.PENCIL') && k16.includes('nwdVar = r3.c(')],
  ['original non-Pencil Shape suppresses TapePattern at the renderer boundary',
    k16.includes('cf0Var.a, cf0Var.b, null, 0, 198144')],
  ['original Shape Pencil main content starts from the fixed seed',
    p16.includes('y4d.b(v4dVar, f != null ? f.floatValue() : 1.0f, f2, 1544949492L')],
  ['original arrow subpath restarts the fallback seed',
    y4d.includes('wg6.q(listA, d, x4dVar, j, null)') &&
      y4d.includes('wg6.q(listA2, d, x4dVar, 1544949492L, null)')],
  ['Shape model retains Tape smart-highlight force effects and tint',
    model.includes('originalTapePattern?: TapePattern | null') &&
      model.includes('originalSmartHighlight?: boolean') &&
      model.includes('originalForce?: number | null') &&
      model.includes('originalInkEffects?: string') &&
      model.includes('originalInkEffectsTinted?: boolean')],
  ['Shape cloning and recognition propagate all retained registers',
    (geometry.match(/originalTapePattern: shape\.originalTapePattern/g)?.length ?? 0) === 3 &&
      recognition.includes('shape.originalSmartHighlight = original?.smartHighlight') &&
      recognition.includes('shape.originalInkEffectsTinted = original?.inkEffectsTinted')],
  ['recognized variable-width Ink downgrades to legal fixed-width Shape style',
    recognition.includes('original?.style === 0 ? 1 : original?.style') &&
      canvas.includes('stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH ? 1')],
  ['Shape bounds use original conservative definition boxes and arrow scale',
    geometry.includes('return transformBounds(localDefinitionBounds(shape), shape.transform)') &&
      geometry.includes('originalShapeArrowScale(shape.strokeWidth) * 46') &&
      geometry.includes('shape.strokeWidth * 2')],
  ['center-path geometry preserves native curves force and closed Polygon semantics',
    strokeGeometry.includes('InkPathCommandType.CUBIC') &&
      strokeGeometry.includes('InkPathCommandType.QUADRATIC') &&
      strokeGeometry.includes('rendered.mainPathEndParameter') &&
      geometry.includes('mainPathEndParameter: trimmed.endParameter') &&
      strokeGeometry.includes('components: [ellipseComponent(shape, force)]') &&
      strokeGeometry.includes('polylineComponent(shape.vertices, true, force)') &&
      strokeGeometry.includes('shape.originalCreate?.averageForce')],
  ['local CREATE_SHAPE emits the complete 18-field aligned table',
    encoder.includes('const root: number = builder.table(fields, 84, 8)') &&
      encoder.includes('builder.uint8(root + 46, tapePattern)') &&
      encoder.includes('builder.uint8(root + 47, 1)') &&
      encoder.includes('builder.uint64Decimal(root + 64, effects)') &&
      encoder.includes('builder.uint8(root + 72, 0)') &&
      encoder.includes('builder.float32(root + 76, force)') &&
      encoder.includes('builder.uint8(root + 80, 1)')],
  ['CREATE_SHAPE encoding validates canonical uint64 and original illegal combinations',
    encoder.includes('validateUnsignedLongDecimal(effects)') &&
      encoder.includes('tint flag has no ink effect') &&
      encoder.includes('ink effects require pen or highlighter') &&
      encoder.includes('polygon.vertices.length < 3')],
  ['decoder and materializer retain all 18 CreateShape fields',
    reducer.includes("rejectFieldsFrom(table, 18, 'CreateShape payload')") &&
      reducer.includes('table.readUint64Decimal(16') &&
      reducer.includes("readBooleanField(table, 17, true") &&
      reducer.includes('originalTapePattern: payload.tapePattern') &&
      reducer.includes('originalForce: payload.force') &&
      reducer.includes('originalInkEffectsTinted: payload.inkEffectsTinted')],
  ['ModifyShape resolves every LWW register before any journal write',
    applyRegistersAt >= 0 && validateResolvedAt > applyRegistersAt && journalAt > validateResolvedAt],
  ['stored Shape metadata restores and validates every retained register',
    persistence.includes('export interface OriginalShapeStateRenderMetadata') &&
      persistence.includes('validateUnsignedLongDecimal(inkEffects)') &&
      persistence.includes('shape.originalTapePattern = originalMetadata.tapePattern') &&
      persistence.includes('shape.originalInkEffectsTinted = originalMetadata.inkEffectsTinted')],
  ['package validation rejects non-ARGB values transparent fill short Polygon and bad effects',
    packageSpec.includes('!isColorInteger(shape.color)') &&
      packageSpec.includes('(shape.fillColor >>> 24 & 0xFF) === 0') &&
      packageSpec.includes('return shape.vertices.length >= 3') &&
      packageSpec.includes('!isUnsignedLongDecimal(shape.originalInkEffects)') &&
      packageSpec.includes("inkEffects !== '0' && shape.originalTool !== 0")],
  ['clipboard promotes legacy force and resets only smart-highlight/create identity',
    clipboard.includes('result.originalForce = shape.originalCreate.averageForce') &&
      clipboard.includes('result.originalSmartHighlight = false') &&
      clipboard.indexOf('result.originalSmartHighlight = false') <
        clipboard.indexOf('result.originalCreate = undefined')],
  ['Shape partial erase preserves force Tape and effect metadata',
    partialEraser.includes('shape.originalForce ?? shape.originalCreate?.averageForce ?? 1') &&
      partialEraser.includes('shape.originalTapePattern ?? TapePattern.STRIPES') &&
      partialEraser.includes('inkEffects: shape.originalInkEffects') &&
      partialEraser.includes('inkEffectsTinted: shape.originalInkEffectsTinted')],
  ['Shape renderer injects the shared renderer and uses bounded Pencil caching',
    renderer.includes('constructor(renderer: StrokeRenderer)') &&
      renderer.includes('MAX_PENCIL_CACHE_ENTRIES: number = 32') &&
      renderer.includes('MAX_PENCIL_CACHE_SPLATS: number = 262144') &&
      renderer.includes('generator.reset(ORIGINAL_PENCIL_FALLBACK_SEED)')],
  ['Shape renderer restores Highlighter alpha without adding a Tape overlay',
    renderer.includes('highlighter ? 107 : undefined') &&
      !renderer.includes('renderTapePattern(')],
  ['main canvas held Shape and thumbnail use the Shape center path and clear Pencil caches',
    canvas.includes('new ShapeCanvasRenderer(this.renderer)') &&
      canvas.includes('renderShape(heldShape, this.renderCtx)') &&
      canvas.includes('renderShape(element.data, renderContext)') &&
      canvas.includes('this.shapeRenderer.clearPencilCache()') &&
      thumbnail.includes('new ShapeCanvasRenderer(this.strokeRenderer)') &&
      thumbnail.includes('renderShape(element.data, renderContext)') &&
      thumbnail.includes('this.shapeRenderer.clearPencilCache()')],
  ['ArkTS fixtures cover rich payload package clipboard eraser persistence and pixels',
    payloadFixture.includes('18446744073709551615') &&
      packageFixture.includes('strictly validates original Shape render registers') &&
      clipboardFixture.includes('promotes Shape force, clears smart highlight') &&
      eraserFixture.includes('preserves Shape force, Tape pattern, and ink effects') &&
      persistenceFixture.includes('strictly decodes every retained original Shape render register') &&
      rendererFixture.includes('original alpha override') &&
      fixtureList.includes('shapeStrokeRendererTest()')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

console.log(`D02_ORIGINAL_SHAPE_RICH_REGISTERS_RENDERING_OK TOTAL=${checks.length} FAILED=0`);
