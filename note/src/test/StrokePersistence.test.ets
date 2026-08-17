import { describe, it, expect } from '@ohos/hypium';
import {
  InkPathCommandType, InkStyle, StrokeElementData, TapePattern,
} from '../main/ets/core/model/StrokeTypes';
import {
  classifyOriginalImageCropMutation, classifyOriginalImageFlipMutation,
  classifyOriginalMathLatexMutation, classifyOriginalPositionLockMutation,
  classifyOriginalRenderMutation,
  decodeOriginalShapeStateRenderMetadata, decodeOriginalShapeStateTool,
  decodePersistedElement, decodeStoredPageElement,
  encodePersistedElement,
  originalClipboardShapeForPaste,
  OriginalClipboardPastePlan, OriginalMathLatexMutation,
  OriginalImageCropMutation, OriginalImageFlipMutation, OriginalPositionLockMutation,
  OriginalPartialErasePlan, OriginalRenderMutation, PersistedElement,
  validateOriginalClipboardPastePlan, validateOriginalPartialErasePlan,
  validatePartialEraseMaterializationPlan,
} from '../main/ets/data/StrokePersistence';
import { PageElementKind } from '../main/ets/core/model/PageElementOrder';
import {
  ElementType, ImageElement, MathElement, ShapeElement, TextBlockElement,
} from '../main/ets/core/model/ElementTypes';
import {
  handwritingSourceChanged, pageSnapshotChanged, SearchSourceElement,
} from '../main/ets/data/SearchIndexPolicy';
import { cloneImageElement } from '../main/ets/core/model/ImageBlockGeometry';
import { cloneShapeElement } from '../main/ets/core/model/ShapeGeometry';
import { cloneMathElement } from '../main/ets/core/model/MathBlockGeometry';

export default function strokePersistenceTest() {
  describe('StrokePersistence payload codec', () => {
    it('round-trips snapshot JSON as UTF-8 BLOB bytes', 0, () => {
      const stroke: StrokeElementData = {
        id: 'stroke-1',
        pathPoints: [],
        cubicSegments: [],
        splatPoints: [],
        renderSpec: {
          color: -16777216,
          brushWidth: 12,
          inkStyle: InkStyle.FIXED_WIDTH,
          isHighlighter: false,
          isPencil: false,
          inkEffects: '18446744073709551615',
          inkEffectsTinted: false,
          inkEffectPhase: -3.25,
        },
        transform: { a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0 },
        bounds: { x: 1, y: 2, width: 3, height: 4 },
        maskPath: [],
        isFinished: true,
      };
      const source: PersistedElement = { kind: 'stroke', data: stroke };
      const bytes: Uint8Array = encodePersistedElement(source);
      const restored: PersistedElement = decodePersistedElement(bytes);
      const restoredStroke: StrokeElementData = restored.data as StrokeElementData;

      expect(bytes.length > 0).assertTrue();
      expect(restored.kind).assertEqual('stroke');
      expect(restoredStroke.id).assertEqual('stroke-1');
      expect(restoredStroke.renderSpec.inkStyle).assertEqual(InkStyle.FIXED_WIDTH);
      expect(restoredStroke.renderSpec.inkEffects).assertEqual('18446744073709551615');
      expect(restoredStroke.renderSpec.inkEffectsTinted).assertFalse();
      expect(restoredStroke.renderSpec.inkEffectPhase).assertEqual(-3.25);
      expect(restoredStroke.bounds.width).assertEqual(3);
    });

    it('binds a stored row kind and ID to its persisted payload', 0, () => {
      const source: PersistedElement = { kind: 'stroke', data: partialEraseStroke('stroke-row') };
      const bytes: Uint8Array = encodePersistedElement(source);
      expect((decodeStoredPageElement('stroke-row', PageElementKind.STROKE, bytes)
        .data as StrokeElementData).id).assertEqual('stroke-row');
      expect(() => decodeStoredPageElement('other', PageElementKind.STROKE, bytes)).assertThrow();
      expect(() => decodeStoredPageElement('stroke-row', PageElementKind.TEXT, bytes)).assertThrow();
      expect(() => decodeStoredPageElement('stroke-row', 0, bytes)).assertThrow();
      expect(() => decodeStoredPageElement('stroke-row', 6, bytes)).assertThrow();
    });

    it('classifies one canonical Math latex-only edit and reverse Undo', 0, () => {
      const before: MathElement = originalMath('op:74:2');
      const after: MathElement = cloneMathElement(before);
      after.latex = '\\sqrt{x}';
      const forward: OriginalMathLatexMutation | null = classifyOriginalMathLatexMutation(
        [mathSource(before)], [mathSource(after)]);
      expect(forward?.identity.timestamp).assertEqual(74);
      expect(forward?.identity.siteId).assertEqual(2);
      expect(forward?.latex).assertEqual('\\sqrt{x}');
      const reverse: OriginalMathLatexMutation | null = classifyOriginalMathLatexMutation(
        [mathSource(after)], [mathSource(before)]);
      expect(reverse?.latex).assertEqual('\\frac{a}{b}');
    });

    it('rejects noncanonical, multi-Math, and unrelated Math edits', 0, () => {
      const before: MathElement = originalMath('op:74:2');
      const after: MathElement = cloneMathElement(before);
      after.latex = 'x';
      const second: MathElement = originalMath('op:76:2');
      const secondAfter: MathElement = cloneMathElement(second);
      secondAfter.latex = 'y';
      expect(classifyOriginalMathLatexMutation(
        [mathSource(before), mathSource(second)],
        [mathSource(after), mathSource(secondAfter)]) === null).assertTrue();
      const unrelated: MathElement = cloneMathElement(after);
      unrelated.color = -65536;
      expect(classifyOriginalMathLatexMutation(
        [mathSource(before)], [mathSource(unrelated)]) === null).assertTrue();
      const local: MathElement = originalMath('local-math');
      const localAfter: MathElement = cloneMathElement(local);
      localAfter.latex = 'z';
      expect(classifyOriginalMathLatexMutation(
        [mathSource(local)], [mathSource(localAfter)]) === null).assertTrue();
    });

    it('rejects malformed snapshot bytes', 0, () => {
      let rejected: boolean = false;
      try {
        decodePersistedElement(new Uint8Array([0x7B]));
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('round-trips original image metadata without sharing decoded arrays', 0, () => {
      const bits: string[] = ['0', '1', '2', '3', '4', '5', '6', '18446744073709551615'];
      const image: ImageElement = {
        id: 'image-1', type: ElementType.IMAGE,
        transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
        bounds: { left: 10, top: 20, right: 110, bottom: 70 },
        assetHash: bits.join(':'), assetHashBits: bits, fileName: '图片.png', mimeType: 'image/png',
        fileSize: 4294967295, intrinsicWidth: 200, intrinsicHeight: 100,
        cropRect: { left: 5, top: 10, right: 195, bottom: 90 },
        blockWidth: 100, blockHeight: 50, rotationRadians: 0, corner: 0, textWrap: 0,
        enableCaption: false, webUrl: null, imageFlippedHorizontally: false,
        imageFlippedVertically: true, positionLocked: false,
      };
      const restored: PersistedElement = decodePersistedElement(
        encodePersistedElement({ kind: 'image', data: image }));
      const restoredImage: ImageElement = restored.data as ImageElement;
      restoredImage.assetHashBits[0] = '99';
      restoredImage.transform[2] = 999;

      expect(restored.kind).assertEqual('image');
      expect(restoredImage.assetHash).assertEqual(image.assetHash);
      expect(restoredImage.fileSize).assertEqual(4294967295);
      expect(image.assetHashBits[0]).assertEqual('0');
      expect(image.transform[2]).assertEqual(10);
    });

    it('preserves imported ink text across no-op and non-ink-only saves', 0, () => {
      const current: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text-old', PageElementKind.TEXT, [3])];
      const unchanged: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text-new', PageElementKind.TEXT, [9]),
        sourceElement('shape', PageElementKind.SHAPE, [4])];

      expect(handwritingSourceChanged(current, unchanged)).assertFalse();
    });

    it('invalidates imported ink text after stroke bytes or order change', 0, () => {
      const current: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2])];
      const changedStroke: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 3])];
      const addedStroke: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('stroke-2', PageElementKind.STROKE, [4])];

      expect(handwritingSourceChanged(current, changedStroke)).assertTrue();
      expect(handwritingSourceChanged(current, addedStroke)).assertTrue();
    });

    it('suppresses only byte-identical ordered page snapshots', 0, () => {
      const current: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text', PageElementKind.TEXT, [3])];
      const same: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text', PageElementKind.TEXT, [3])];
      const reordered: SearchSourceElement[] = [sourceElement('text', PageElementKind.TEXT, [3]),
        sourceElement('stroke', PageElementKind.STROKE, [1, 2])];
      const textChanged: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text', PageElementKind.TEXT, [4])];

      expect(pageSnapshotChanged(current, same)).assertFalse();
      expect(pageSnapshotChanged(current, reordered)).assertTrue();
      expect(pageSnapshotChanged(current, textChanged)).assertTrue();
    });

    it('classifies image-only horizontal and vertical flip register writes', 0, () => {
      const first: ImageElement = originalImage('op:14:2');
      const second: ImageElement = originalImage('op:16:4');
      second.imageFlippedHorizontally = true;
      const firstHorizontal: ImageElement = cloneImageElement(first);
      const secondHorizontal: ImageElement = cloneImageElement(second);
      firstHorizontal.imageFlippedHorizontally = true;
      secondHorizontal.imageFlippedHorizontally = false;
      const current: SearchSourceElement[] = [imageSource(first), imageSource(second)];
      const afterHorizontal: SearchSourceElement[] = [
        imageSource(firstHorizontal), imageSource(secondHorizontal),
      ];
      const horizontal: OriginalImageFlipMutation | null =
        classifyOriginalImageFlipMutation(current, afterHorizontal);
      expect(horizontal?.updates.length).assertEqual(2);
      expect(horizontal?.updates[0].horizontal).assertTrue();
      expect(horizontal?.updates[0].vertical === null).assertTrue();
      expect(horizontal?.updates[1].horizontal).assertFalse();

      const firstVertical: ImageElement = cloneImageElement(firstHorizontal);
      const secondVertical: ImageElement = cloneImageElement(secondHorizontal);
      firstVertical.imageFlippedVertically = true;
      secondVertical.imageFlippedVertically = true;
      const vertical: OriginalImageFlipMutation | null = classifyOriginalImageFlipMutation(
        afterHorizontal, [imageSource(firstVertical), imageSource(secondVertical)]);
      expect(vertical?.updates[0].horizontal === null).assertTrue();
      expect(vertical?.updates[0].vertical).assertTrue();
    });

    it('classifies explicit false and reverse image flip writes for Undo and Redo', 0, () => {
      const before: ImageElement = originalImage('op:14:2');
      before.imageFlippedHorizontally = true;
      const after: ImageElement = cloneImageElement(before);
      after.imageFlippedHorizontally = false;
      const forward: OriginalImageFlipMutation | null = classifyOriginalImageFlipMutation(
        [imageSource(before)], [imageSource(after)]);
      const reverse: OriginalImageFlipMutation | null = classifyOriginalImageFlipMutation(
        [imageSource(after)], [imageSource(before)]);
      expect(forward?.updates[0].horizontal).assertFalse();
      expect(reverse?.updates[0].horizontal).assertTrue();
    });

    it('mirrors an existing crop rect with the original image flip register', 0, () => {
      const before: ImageElement = originalImage('op:14:2');
      before.cropRect = { left: 20, top: 10, right: 100, bottom: 50 };
      const after: ImageElement = cloneImageElement(before);
      after.imageFlippedHorizontally = true;
      after.cropRect = { left: 100, top: 10, right: 180, bottom: 50 };
      const mutation: OriginalImageFlipMutation | null = classifyOriginalImageFlipMutation(
        [imageSource(before)], [imageSource(after)]);
      expect(mutation?.updates[0].cropRect?.x).assertEqual(100);
      expect(mutation?.updates[0].cropRect?.width).assertEqual(80);

      const unmirrored: ImageElement = cloneImageElement(before);
      unmirrored.imageFlippedHorizontally = true;
      expect(classifyOriginalImageFlipMutation(
        [imageSource(before)], [imageSource(unmirrored)]) === null).assertTrue();
    });

    it('rejects mixed-axis, non-image, and unrelated image mutations', 0, () => {
      const first: ImageElement = originalImage('op:14:2');
      const second: ImageElement = originalImage('op:16:4');
      const firstHorizontal: ImageElement = cloneImageElement(first);
      const secondVertical: ImageElement = cloneImageElement(second);
      firstHorizontal.imageFlippedHorizontally = true;
      secondVertical.imageFlippedVertically = true;
      expect(classifyOriginalImageFlipMutation(
        [imageSource(first), imageSource(second)],
        [imageSource(firstHorizontal), imageSource(secondVertical)]) === null).assertTrue();

      const unrelated: ImageElement = cloneImageElement(firstHorizontal);
      unrelated.corner = 1;
      expect(classifyOriginalImageFlipMutation(
        [imageSource(first)], [imageSource(unrelated)]) === null).assertTrue();
      expect(classifyOriginalImageFlipMutation(
        [sourceElement('stroke', PageElementKind.STROKE, [1])],
        [sourceElement('stroke', PageElementKind.STROKE, [2])]) === null).assertTrue();
    });

    it('classifies the original composite image crop and reverse nullable clear', 0, () => {
      const before: ImageElement = canonicalOriginalImage('op:14:2');
      const after: ImageElement = cloneImageElement(before);
      after.cropRect = { left: 20, top: 10, right: 180, bottom: 90 };
      after.blockWidth = 160;
      after.blockHeight = 80;
      after.transform[2] = 30;
      after.transform[5] = 30;
      after.bounds = { left: 30, top: 30, right: 190, bottom: 110 };
      const forward: OriginalImageCropMutation | null = classifyOriginalImageCropMutation(
        [imageSource(before)], [imageSource(after)]);
      expect(forward?.updates.length).assertEqual(1);
      expect(forward?.updates[0].originX).assertEqual(30);
      expect(forward?.updates[0].originY).assertEqual(30);
      expect(forward?.updates[0].width).assertEqual(160);
      expect(forward?.updates[0].cropRect?.x).assertEqual(20);

      const reverse: OriginalImageCropMutation | null = classifyOriginalImageCropMutation(
        [imageSource(after)], [imageSource(before)]);
      expect(reverse?.updates[0].originX).assertEqual(10);
      expect(reverse?.updates[0].originY).assertEqual(20);
      expect(reverse?.updates[0].cropRect === null).assertTrue();
    });

    it('classifies Reset confirmation as a full intrinsic crop rect', 0, () => {
      const before: ImageElement = canonicalOriginalImage('op:14:2');
      before.cropRect = { left: 20, top: 10, right: 180, bottom: 90 };
      before.blockWidth = 160;
      before.blockHeight = 80;
      before.transform[2] = 30;
      before.transform[5] = 30;
      before.bounds = { left: 30, top: 30, right: 190, bottom: 110 };
      const after: ImageElement = canonicalOriginalImage('op:14:2');
      after.cropRect = { left: 0, top: 0, right: 200, bottom: 100 };
      const mutation: OriginalImageCropMutation | null = classifyOriginalImageCropMutation(
        [imageSource(before)], [imageSource(after)]);
      expect(mutation?.updates[0].cropRect?.x).assertEqual(0);
      expect(mutation?.updates[0].cropRect?.width).assertEqual(200);
      expect(mutation?.updates[0].width).assertEqual(200);
      expect(mutation?.updates[0].height).assertEqual(100);
    });

    it('rejects multi-image, scale, and unrelated composite crop mutations', 0, () => {
      const first: ImageElement = canonicalOriginalImage('op:14:2');
      const second: ImageElement = canonicalOriginalImage('op:16:4');
      const firstCrop: ImageElement = cropOriginalImage(first, 10, 10, 180, 80);
      const secondCrop: ImageElement = cropOriginalImage(second, 5, 5, 190, 90);
      expect(classifyOriginalImageCropMutation(
        [imageSource(first), imageSource(second)],
        [imageSource(firstCrop), imageSource(secondCrop)]) === null).assertTrue();

      const scaleChanged: ImageElement = cloneImageElement(firstCrop);
      scaleChanged.transform[0] = 2;
      scaleChanged.bounds = { left: 20, top: 30, right: 380, bottom: 110 };
      expect(classifyOriginalImageCropMutation(
        [imageSource(first)], [imageSource(scaleChanged)]) === null).assertTrue();
      const unrelated: ImageElement = cloneImageElement(firstCrop);
      unrelated.corner = 1;
      expect(classifyOriginalImageCropMutation(
        [imageSource(first)], [imageSource(unrelated)]) === null).assertTrue();
    });

    it('classifies original Shape render tuples and reverse Undo values', 0, () => {
      const marker: ShapeElement = originalShape('op:20:2', 2, 0x6B102030, 12, 0x6B102030);
      const pen: ShapeElement = originalShape('op:22:4', 0, -15720400, 3, null);
      const markerAfter: ShapeElement = cloneShapeElement(marker);
      markerAfter.color = 0x6B445566;
      markerAfter.fillColor = 0x6B445566;
      markerAfter.strokeWidth = 30;
      markerAfter.originalStyle = 2;
      const penAfter: ShapeElement = cloneShapeElement(pen);
      penAfter.color = -12298906;
      penAfter.strokeWidth = 30;
      const forward: OriginalRenderMutation | null = classifyOriginalRenderMutation(
        [shapeSource(marker), shapeSource(pen)], [shapeSource(markerAfter), shapeSource(penAfter)]);
      expect(forward?.inkBatches.length).assertEqual(0);
      expect(forward?.shapeBatches.length).assertEqual(2);
      expect(forward?.shapeBatches[0].fillColorPresent).assertTrue();
      expect(forward?.shapeBatches[0].fillColor).assertEqual(0x6B445566);
      expect(forward?.shapeBatches[0].expectedTools[0]).assertEqual(2);
      expect(forward?.shapeBatches[0].expectedStyles[0]).assertEqual(1);
      expect(forward?.shapeBatches[0].style).assertEqual(2);
      expect(forward?.shapeBatches[1].fillColorPresent).assertFalse();
      expect(forward?.shapeBatches[1].borderWidth).assertEqual(30);
      expect(forward?.shapeBatches[1].expectedTools[0]).assertEqual(0);

      const reverse: OriginalRenderMutation | null = classifyOriginalRenderMutation(
        [shapeSource(markerAfter), shapeSource(penAfter)], [shapeSource(marker), shapeSource(pen)]);
      expect(reverse?.shapeBatches.length).assertEqual(2);
      expect(reverse?.shapeBatches[0].borderWidth).assertEqual(12);
      expect(reverse?.shapeBatches[0].expectedStyles[0]).assertEqual(2);
      expect(reverse?.shapeBatches[0].style).assertEqual(1);
      expect(reverse?.shapeBatches[1].borderWidth).assertEqual(3);
    });

    it('strictly decodes the original Shape state tool preflight', 0, () => {
      expect(decodeOriginalShapeStateTool(
        '{"tool":2,"style":1,"positionLocked":false}')).assertEqual(2);
      expect(decodeOriginalShapeStateTool(
        '{"tool":7,"style":3,"positionLocked":true}')).assertEqual(7);
      // Pre-Phase-121 resolved rows predate the retained register. FlatBuffer defaults it false.
      expect(decodeOriginalShapeStateTool('{"tool":2,"style":1}')).assertEqual(2);
      expect(decodeOriginalShapeStateTool(
        '{"tool":8,"style":1,"positionLocked":false}') === null).assertTrue();
      expect(decodeOriginalShapeStateTool(
        '{"tool":1.5,"style":1,"positionLocked":false}') === null).assertTrue();
      expect(decodeOriginalShapeStateTool(
        '{"tool":"2","style":1,"positionLocked":false}') === null).assertTrue();
      expect(decodeOriginalShapeStateTool(
        '{"tool":2,"style":0,"positionLocked":false}') === null).assertTrue();
      expect(decodeOriginalShapeStateTool(
        '{"tool":2,"style":1,"positionLocked":0}') === null).assertTrue();
      expect(decodeOriginalShapeStateTool('{broken') === null).assertTrue();
    });

    it('strictly decodes every retained original Shape render register', 0, () => {
      const tape = decodeOriginalShapeStateRenderMetadata(
        `{"tool":3,"style":2,"tapePattern":${TapePattern.HEARTS},` +
        '"smartHighlight":true,"force":0.25,"positionLocked":true,' +
        '"inkEffects":"0","inkEffectsTinted":true}');
      expect(tape === null).assertFalse();
      expect(tape?.tool).assertEqual(3);
      expect(tape?.style).assertEqual(2);
      expect(tape?.tapePattern).assertEqual(TapePattern.HEARTS);
      expect(tape?.smartHighlight).assertTrue();
      expect(tape?.force).assertEqual(0.25);
      expect(tape?.positionLocked).assertTrue();

      const effect = decodeOriginalShapeStateRenderMetadata(
        '{"tool":0,"style":1,"inkEffects":"18446744073709551615",' +
        '"inkEffectsTinted":false}');
      expect(effect?.inkEffects).assertEqual('18446744073709551615');
      expect(effect?.inkEffectsTinted).assertFalse();
      expect(effect?.smartHighlight).assertFalse();
      expect(effect?.force === null).assertTrue();

      expect(decodeOriginalShapeStateRenderMetadata(
        `{"tool":0,"style":1,"tapePattern":${TapePattern.HEARTS}}`)?.tapePattern)
        .assertEqual(TapePattern.HEARTS);
      expect(decodeOriginalShapeStateRenderMetadata(
        '{"tool":0,"style":1,"tapePattern":9}') === null).assertTrue();
      expect(decodeOriginalShapeStateRenderMetadata(
        '{"tool":0,"style":1,"force":1e999}') === null).assertTrue();
      expect(decodeOriginalShapeStateRenderMetadata(
        '{"tool":0,"style":1,"inkEffects":"18446744073709551616"}') === null).assertTrue();
      expect(decodeOriginalShapeStateRenderMetadata(
        '{"tool":1,"style":1,"inkEffects":"1"}') === null).assertTrue();
      expect(decodeOriginalShapeStateRenderMetadata(
        '{"tool":0,"style":1,"inkEffects":"0","inkEffectsTinted":false}') === null)
        .assertTrue();
    });

    it('rejects unrelated Shape geometry from the render register writer', 0, () => {
      const before: ShapeElement = originalShape('op:24:6', 0, -16777216, 4, null);
      const after: ShapeElement = cloneShapeElement(before);
      if (after.type === ElementType.POLYGON) {
        after.vertices[0].x = 9;
      }
      after.color = -15654349;
      expect(classifyOriginalRenderMutation(
        [shapeSource(before)], [shapeSource(after)]) === null).assertTrue();
    });

    it('classifies mixed Shape and Block lock with reversible source state', 0, () => {
      const shape: ShapeElement = originalShape('op:50:2', 0, -16777216, 4, null);
      shape.positionLocked = false;
      const image: ImageElement = originalImage('op:51:3');
      const lockedShape: ShapeElement = cloneShapeElement(shape);
      lockedShape.positionLocked = true;
      const lockedImage: ImageElement = cloneImageElement(image);
      lockedImage.positionLocked = true;
      const forward: OriginalPositionLockMutation | null = classifyOriginalPositionLockMutation(
        [shapeSource(shape), imageSource(image)],
        [shapeSource(lockedShape), imageSource(lockedImage)]);
      expect(forward?.shapeBatches.length).assertEqual(1);
      expect(forward?.shapeBatches[0].locked).assertTrue();
      expect(forward?.shapeBatches[0].expectedLocked[0]).assertFalse();
      expect(forward?.blockBatches.length).assertEqual(1);
      expect(forward?.blockBatches[0].identities[0].timestamp).assertEqual(51);
      const reverse: OriginalPositionLockMutation | null = classifyOriginalPositionLockMutation(
        [shapeSource(lockedShape), imageSource(lockedImage)],
        [shapeSource(shape), imageSource(image)]);
      expect(reverse?.shapeBatches[0].locked).assertFalse();
      expect(reverse?.shapeBatches[0].expectedLocked[0]).assertTrue();
      const invalid: ImageElement = cloneImageElement(image);
      invalid.positionLocked = true;
      invalid.blockWidth = 101;
      expect(classifyOriginalPositionLockMutation(
        [imageSource(image)], [imageSource(invalid)]) === null).assertTrue();
    });

    it('validates bottom-up original clipboard Paste plans before persistence', 0, () => {
      const first: ShapeElement = originalShape('op:50:2', 0, -16777216, 4, null);
      const second: ShapeElement = originalShape('op:52:2', 0, -16777216, 4, null);
      const third: ShapeElement = originalShape('op:54:2', 0, -16777216, 4, null);
      const valid: OriginalClipboardPastePlan = {
        strokes: [], shapes: [first, second, third], textBlocks: [], images: [], mathBlocks: [],
        elementOrder: [
          { kind: PageElementKind.SHAPE, elementId: first.id, zIndex: 0 },
          { kind: PageElementKind.SHAPE, elementId: second.id, zIndex: 1 },
          { kind: PageElementKind.SHAPE, elementId: third.id, zIndex: 2 },
        ],
        groups: [
          { id: 'op:60:2', timestamp: 60, siteId: 2, members: [first.id, second.id] },
          { id: 'op:62:2', timestamp: 62, siteId: 2, members: ['op:60:2', third.id] },
        ],
        topGroupIds: ['op:62:2'],
      };
      validateOriginalClipboardPastePlan(valid);
      let rejected: number = 0;
      try {
        validateOriginalClipboardPastePlan({
          strokes: [], shapes: valid.shapes, textBlocks: [], images: [], mathBlocks: [],
          elementOrder: valid.elementOrder,
          groups: [valid.groups[1], valid.groups[0]], topGroupIds: valid.topGroupIds,
        });
      } catch (_error) {
        rejected++;
      }
      const invalidImage: ImageElement = originalImage('op:70:2');
      invalidImage.assetHash = 'not-the-eight-word-key';
      try {
        validateOriginalClipboardPastePlan({
          strokes: [], shapes: [], textBlocks: [], images: [invalidImage],
          mathBlocks: [],
          elementOrder: [{ kind: PageElementKind.IMAGE, elementId: 'op:70:2', zIndex: 0 }],
          groups: [{ id: 'op:72:2', timestamp: 72, siteId: 2, members: ['op:70:2'] }],
          topGroupIds: ['op:72:2'],
        });
      } catch (_error) {
        rejected++;
      }
      const image: ImageElement = originalImage('op:70:2');
      const math: MathElement = originalMath('op:74:2');
      const text: TextBlockElement = originalText('op:73:2', '');
      validateOriginalClipboardPastePlan({
        strokes: [], shapes: [], textBlocks: [text], images: [image], mathBlocks: [math],
        elementOrder: [
          { kind: PageElementKind.IMAGE, elementId: image.id, zIndex: 0 },
          { kind: PageElementKind.TEXT, elementId: text.id, zIndex: 1 },
          { kind: PageElementKind.MATH, elementId: math.id, zIndex: 2 },
        ],
        groups: [{
          id: 'op:76:2', timestamp: 76, siteId: 2, members: [image.id, text.id, math.id],
        }],
        topGroupIds: ['op:76:2'],
      });
      expect(rejected).assertEqual(2);
    });

    it('rejects a partial-erase source identity already used by an earlier remnant', 0, () => {
      const firstSource: StrokeElementData = partialEraseStroke('op:50:2');
      const secondSource: StrokeElementData = partialEraseStroke('op:52:2');
      const valid: OriginalPartialErasePlan = {
        replacements: [{
          sourceKind: PageElementKind.STROKE,
          source: firstSource, remnants: [partialEraseStroke('draft-remnant')],
        }, { sourceKind: PageElementKind.STROKE, source: secondSource, remnants: [] }],
      };
      validateOriginalPartialErasePlan(valid);
      let rejected: boolean = false;
      try {
        validateOriginalPartialErasePlan({
          replacements: [{
            sourceKind: PageElementKind.STROKE,
            source: firstSource, remnants: [partialEraseStroke(secondSource.id)],
          }, { sourceKind: PageElementKind.STROKE, source: secondSource, remnants: [] }],
        });
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('preflights local partial-erase remnants before deleting their source', 0, () => {
      const source: StrokeElementData = partialEraseStroke('local-source');
      const remnant: StrokeElementData = partialEraseStroke('local-remnant');
      validatePartialEraseMaterializationPlan({
        replacements: [{
          sourceKind: PageElementKind.STROKE, source: source, remnants: [remnant],
        }],
      });

      remnant.renderSpec.inkEffects = 'not-a-uint64';
      let rejected: boolean = false;
      try {
        validatePartialEraseMaterializationPlan({
          replacements: [{
            sourceKind: PageElementKind.STROKE, source: source, remnants: [remnant],
          }],
        });
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('accepts a canonical Shape source that is replaced by auxiliary-path Ink', 0, () => {
      const source: ShapeElement = originalShape('op:54:2', 0, -16777216, 4, 0x6B102030);
      const remnant: StrokeElementData = partialEraseStroke('shape-remnant');
      remnant.customPath = [
        { type: InkPathCommandType.MOVE_TO, points: [{ x: 0, y: 0 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 10, y: 0 }] },
      ];
      remnant.fillPath = [
        { type: InkPathCommandType.MOVE_TO, points: [{ x: 0, y: 0 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 10, y: 0 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 0, y: 0 }] },
      ];
      remnant.fillColor = source.fillColor;
      validateOriginalPartialErasePlan({
        replacements: [{
          sourceKind: PageElementKind.SHAPE, source: source, remnants: [remnant],
        }],
      });
    });

    it('resets Shape RichText during original clipboard Paste without mutating source', 0, () => {
      const source: ShapeElement = originalShape('op:80:2', 0, -16777216, 4, null);
      source.originalSmartHighlight = true;
      source.originalInkEffects = '18446744073709551615';
      source.originalInkEffectsTinted = false;
      source.originalCreate = {
        timestamp: 80, siteId: 2, clientTime: 1000,
        pageTimestamp: 16, pageSiteId: 2, pageIndex: 0,
        pencilSeed: 0, averageForce: 0.625,
      };
      source.richText = 'AB';
      source.characterStyleRuns = [{ start: 0, end: 2, style: { bold: true } }];
      source.paragraphStyleRuns = [{
        start: 0, end: 2, style: { alignment: 2, decoratorStyle: 1 },
      }];
      const copy: ShapeElement = originalClipboardShapeForPaste(source);
      expect(copy.richText).assertEqual('');
      expect(copy.characterStyleRuns?.length).assertEqual(0);
      expect(copy.paragraphStyleRuns?.length).assertEqual(0);
      expect(copy.originalForce).assertEqual(0.625);
      expect(copy.originalSmartHighlight).assertFalse();
      expect(copy.originalInkEffects).assertEqual('18446744073709551615');
      expect(copy.originalInkEffectsTinted).assertFalse();
      expect(source.richText).assertEqual('AB');
      expect(source.originalSmartHighlight).assertTrue();
      expect(source.characterStyleRuns?.length).assertEqual(1);
      expect(source.paragraphStyleRuns?.length).assertEqual(1);
      validateOriginalClipboardPastePlan({
        strokes: [], shapes: [source], textBlocks: [], images: [], mathBlocks: [],
        elementOrder: [{ kind: PageElementKind.SHAPE, elementId: source.id, zIndex: 0 }],
        groups: [{ id: 'op:82:2', timestamp: 82, siteId: 2, members: [source.id] }],
        topGroupIds: ['op:82:2'],
      });
    });
  });
}

function partialEraseStroke(id: string): StrokeElementData {
  return {
    id: id,
    pathPoints: [
      { position: { x: 0, y: 0 }, widthFactor: 1, pressure: 1,
        altitudeAngleRadians: 1, azimuthUnitX: 1, azimuthUnitY: 0 },
      { position: { x: 10, y: 0 }, widthFactor: 1, pressure: 1,
        altitudeAngleRadians: 1, azimuthUnitX: 1, azimuthUnitY: 0 },
    ],
    cubicSegments: [{
      p0: { x: 0, y: 0 }, p1: { x: 3, y: 0 },
      p2: { x: 7, y: 0 }, p3: { x: 10, y: 0 },
    }],
    splatPoints: [],
    renderSpec: {
      color: -16777216, brushWidth: 2, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false, isPencil: false,
    },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: -1, top: -1, right: 11, bottom: 1 },
    maskPath: [], isFinished: true,
  };
}

function originalImage(id: string): ImageElement {
  const bits: string[] = ['0', '1', '2', '3', '4', '5', '6', '7'];
  return {
    id: id, type: ElementType.IMAGE, transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 110, bottom: 70 },
    assetHash: bits.join(':'), assetHashBits: bits, fileName: 'photo.png', mimeType: 'image/png',
    fileSize: 100, intrinsicWidth: 200, intrinsicHeight: 100, cropRect: null,
    blockWidth: 100, blockHeight: 50, rotationRadians: 0, corner: 0, textWrap: 0,
    enableCaption: false, webUrl: null, imageFlippedHorizontally: false,
    imageFlippedVertically: false, positionLocked: false,
  };
}

function originalMath(id: string): MathElement {
  return {
    id: id, type: ElementType.MATH, transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 110, bottom: 70 },
    latex: '\\frac{a}{b}', color: -16777216,
    blockWidth: 100, blockHeight: 50, rotationRadians: 0,
    corner: 0, textWrap: 0, enableCaption: false, positionLocked: false,
  };
}

function mathSource(math: MathElement): SearchSourceElement {
  return {
    elementId: math.id, kind: PageElementKind.MATH,
    payload: encodePersistedElement({ kind: 'math', data: math }),
  };
}

function originalText(id: string, richText: string): TextBlockElement {
  return {
    id: id, type: ElementType.TEXT, transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 110, bottom: 70 }, richText: richText,
    textOrigin: { x: 0, y: 0 }, blockWidth: 100, blockHeight: 50,
    rotationRadians: 0, contentLeftInset: 5, contentTopInset: 3,
    fontSize: 17, fontColor: -16777216,
  };
}

function canonicalOriginalImage(id: string): ImageElement {
  const image: ImageElement = originalImage(id);
  image.blockWidth = 200;
  image.blockHeight = 100;
  image.bounds = { left: 10, top: 20, right: 210, bottom: 120 };
  return image;
}

function cropOriginalImage(source: ImageElement, left: number, top: number,
  right: number, bottom: number): ImageElement {
  const image: ImageElement = cloneImageElement(source);
  image.cropRect = { left: left, top: top, right: right, bottom: bottom };
  image.blockWidth = right - left;
  image.blockHeight = bottom - top;
  image.transform[2] = source.transform[2] + left;
  image.transform[5] = source.transform[5] + top;
  image.bounds = {
    left: image.transform[2], top: image.transform[5],
    right: image.transform[2] + image.blockWidth,
    bottom: image.transform[5] + image.blockHeight,
  };
  return image;
}

function imageSource(image: ImageElement): SearchSourceElement {
  return {
    elementId: image.id, kind: PageElementKind.IMAGE,
    payload: encodePersistedElement({ kind: 'image', data: image }),
  };
}

function originalShape(id: string, tool: number, color: number, width: number,
  fillColor: number | null): ShapeElement {
  return {
    id: id, type: ElementType.POLYGON, transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 10, bottom: 10 },
    vertices: [{ x: 0, y: 0 }, { x: 10, y: 0 }, { x: 10, y: 10 }], isClosed: true,
    color: color, strokeWidth: width, fillColor: fillColor, originalTool: tool,
    originalStyle: 1,
  };
}

function shapeSource(shape: ShapeElement): SearchSourceElement {
  return {
    elementId: shape.id, kind: PageElementKind.SHAPE,
    payload: encodePersistedElement({ kind: 'shape', data: shape }),
  };
}

function sourceElement(elementId: string, kind: number, bytes: number[]): SearchSourceElement {
  return { elementId: elementId, kind: kind, payload: new Uint8Array(bytes) };
}
