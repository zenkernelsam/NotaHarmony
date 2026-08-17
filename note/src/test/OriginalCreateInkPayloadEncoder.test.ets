import { describe, expect, it } from '@ohos/hypium';
import {
  InkPathCommandType, InkStyle, StrokeElementData, TapePattern,
} from '../main/ets/core/model/StrokeTypes';
import {
  ElementType, ShapeArrowHead, ShapeElement,
} from '../main/ets/core/model/ElementTypes';
import {
  decodeOriginalCreateInk, unsupportedOriginalCreateInkReason,
} from '../main/ets/data/OriginalCreateInkOperation';
import { encodeOriginalLocalCreateInk } from
  '../main/ets/data/OriginalCreateInkPayloadEncoder';
import { encodeOriginalLocalCreateShape } from
  '../main/ets/data/OriginalCreateShapePayloadEncoder';
import { decodeOperationId } from '../main/ets/data/OperationIdentity';
import { encodeOriginalEntityVisibility } from
  '../main/ets/data/OriginalDeleteEntitiesPayloadEncoder';
import {
  decodeOriginalDeleteEntities, MAX_ORIGINAL_DELETE_ENTITY_COUNT,
} from '../main/ets/data/OriginalDeleteEntitiesOperation';
import { encodeOriginalInkRenderRegisters } from
  '../main/ets/data/OriginalModifyInkPayloadEncoder';
import { decodeOriginalModifyInk } from '../main/ets/data/OriginalModifyInkOperation';
import { encodeOriginalShapeRenderRegisters } from
  '../main/ets/data/OriginalModifyShapePayloadEncoder';
import {
  decodeOriginalCreateShape, decodeOriginalModifyShape, OriginalEllipseDefinition,
  OriginalLineDefinition, OriginalPolygonDefinition,
} from '../main/ets/data/OriginalShapeGroupOperation';
import { decodeOriginalModifyPositions } from
  '../main/ets/data/OriginalModifyPositionsOperation';
import { encodeOriginalModifyPositions } from
  '../main/ets/data/OriginalModifyPositionsPayloadEncoder';
import { decodeOriginalAddPathElements } from
  '../main/ets/data/OriginalAddPathElementsOperation';
import { decodeOriginalInkPathAppend } from '../main/ets/data/OriginalInkPathCodec';
import { encodeOriginalInkPathAppend } from '../main/ets/data/OriginalInkPathEncoder';
import { encodeOriginalAddPathElementsPayload } from
  '../main/ets/data/OriginalAddPathElementsPayloadEncoder';
import { encodeOriginalOperationEnvelope } from
  '../main/ets/data/OriginalOperationEnvelopeEncoder';
import { OriginalFlatBufferTableReader, parseOriginalOperationEnvelope,
  parseOriginalSyncedOperationEnvelope } from
  '../main/ets/data/OriginalSyncedOperationFlatBuffer';
import { decodeOriginalTransientInteractionEnded, decodeOriginalTransientInteractionMetadata } from
  '../main/ets/data/OriginalTransientInteractionOperation';
import { encodeOriginalTransientInteractionEndedPayload } from
  '../main/ets/data/OriginalTransientInteractionPayloadEncoder';
import { SearchSourceElement } from '../main/ets/data/SearchIndexPolicy';
import { createPageMutation } from '../main/ets/data/PageMutationOpCodec';
import { PageElementKind } from '../main/ets/core/model/PageElementOrder';
import {
  decodeOriginalPartialEraseMutation, encodeOriginalPartialEraseMutation,
  validateOriginalPartialEraseMutation,
} from '../main/ets/data/OriginalPartialEraseMutationCodec';

export default function originalCreateInkPayloadEncoderTest() {
  describe('OriginalCreateInkPayloadEncoder', () => {
    it('round-trips a BITS_32 cubic local pen through dm2', 0, () => {
      const stroke: StrokeElementData = sampleStroke();
      const decoded = decodeOriginalCreateInk(wrap(15, encodeOriginalLocalCreateInk(
        { timestamp: 80, siteId: 7, index: 2 }, stroke)), '1234');
      expect(decoded.page.timestamp).assertEqual(80);
      expect(decoded.page.siteId).assertEqual(7);
      expect(decoded.page.index).assertEqual(2);
      expect(decoded.tool).assertEqual(0);
      expect(decoded.style).assertEqual(0);
      expect(decoded.color).assertEqual(stroke.renderSpec.color);
      expect(decoded.width).assertEqual(4.5);
      expect(decoded.zIndex).assertEqual('1234');
      expect(decoded.path?.pathPoints.length).assertEqual(2);
      expect(decoded.path?.cubicSegments.length).assertEqual(1);
      expect(decoded.path?.cubicSegments[0].p1.x).assertEqual(2);
      expect(decoded.path?.cubicSegments[0].p2.y).assertEqual(4);
      expect(decoded.path?.cubicSegments[0].p3.x).assertEqual(6);
      stroke.renderSpec.isPencil = true;
      stroke.styleMap = [{ backingPencilSeed: -1234,
        backingPencilReferencePoint: { x: 0, y: 0 },
        backingDashPhase: 0, backingDashPeriod: 0 }];
      const pencil = decodeOriginalCreateInk(wrap(15, encodeOriginalLocalCreateInk(
        { timestamp: 80, siteId: 7, index: 2 }, stroke)), '1234');
      expect(pencil.tool).assertEqual(1);
      expect(pencil.styleMap[0].backingPencilSeed).assertEqual(-1234);
    });

    it('preserves CREATE_INK origin rotation scale and source z-index for erase remnants', 0, () => {
      const stroke: StrokeElementData = sampleStroke();
      stroke.transform = [0, -0.5, 12.5, 2, 0, -4.25, 0, 0, 1];
      const decoded = decodeOriginalCreateInk(wrap(15, encodeOriginalLocalCreateInk(
        { timestamp: 80, siteId: 7, index: 2 }, stroke, '987654321')), '1234');
      expect(decoded.originX).assertEqual(12.5);
      expect(decoded.originY).assertEqual(-4.25);
      expect(Math.abs(decoded.rotation - Math.PI / 2) < 0.000001).assertTrue();
      expect(decoded.scaleX).assertEqual(2);
      expect(decoded.scaleY).assertEqual(0.5);
      expect(decoded.zIndex).assertEqual('987654321');
    });

    it('round-trips multi-component custom/fill paths and fill color for Shape remnants', 0, () => {
      const stroke: StrokeElementData = sampleStroke();
      stroke.customPath = [
        { type: InkPathCommandType.MOVE_TO, points: [{ x: 0, y: 0 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 8, y: 0 }] },
        { type: InkPathCommandType.QUADRATIC,
          points: [{ x: 10, y: 2 }, { x: 8, y: 4 }] },
        { type: InkPathCommandType.CUBIC,
          points: [{ x: 6, y: 6 }, { x: 2, y: 6 }, { x: 0, y: 4 }] },
        { type: InkPathCommandType.MOVE_TO, points: [{ x: 20, y: 20 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 24, y: 20 }] },
      ];
      stroke.fillPath = [
        { type: InkPathCommandType.MOVE_TO, points: [{ x: 1, y: 1 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 7, y: 1 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 7, y: 3 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 1, y: 3 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 1, y: 1 }] },
      ];
      stroke.fillColor = 0x6B112233;
      stroke.transform = [0, -0.5, 12.5, 2, 0, -4.25, 0, 0, 1];
      const decoded = decodeOriginalCreateInk(wrap(15, encodeOriginalLocalCreateInk(
        { timestamp: 80, siteId: 7, index: 2 }, stroke, '987654321')), '1234');
      expect(decoded.customPath?.commands.length).assertEqual(6);
      expect(decoded.customPath?.commands[0].type).assertEqual(InkPathCommandType.MOVE_TO);
      expect(decoded.customPath?.commands[3].type).assertEqual(InkPathCommandType.CUBIC);
      expect(decoded.customPath?.commands[3].points[2].x).assertEqual(0);
      expect(decoded.customPath?.commands[4].points[0].x).assertEqual(20);
      expect(decoded.fillPath?.commands.length).assertEqual(5);
      expect(decoded.fillPath?.commands[2].points[0].y).assertEqual(3);
      expect(decoded.fillColor).assertEqual(0x6B112233);
      expect(decoded.originX).assertEqual(12.5);
      expect(decoded.zIndex).assertEqual('987654321');
    });

    it('preserves the uint32 audio interval on CREATE_INK erase remnants', 0, () => {
      const stroke: StrokeElementData = sampleStroke();
      stroke.audioDuration = 0xFFFFFFFF;
      const decoded = decodeOriginalCreateInk(wrap(15, encodeOriginalLocalCreateInk(
        { timestamp: 80, siteId: 7, index: 2 }, stroke)), '1234');
      expect(decoded.audioDuration).assertEqual(0xFFFFFFFF);
      stroke.audioDuration = -1;
      expect(() => encodeOriginalLocalCreateInk(
        { timestamp: 80, siteId: 7, index: 2 }, stroke)).assertThrow();
    });

    it('encodes batched entity delete and undelete vectors without changing identity', 0, () => {
      const decoded = decodeOriginalDeleteEntities(wrap(25, encodeOriginalEntityVisibility(
        [{ timestamp: 20, siteId: 2 }, { timestamp: 22, siteId: 4 },
          { timestamp: 24, siteId: 6 }],
        [{ timestamp: 21, siteId: 3 }, { timestamp: 23, siteId: 5 }])));
      expect(decoded.entityDeletes.length).assertEqual(3);
      expect(decoded.entityDeletes[0].timestamp).assertEqual(20);
      expect(decoded.entityDeletes[2].siteId).assertEqual(6);
      expect(decoded.entityUndeletes.length).assertEqual(2);
      expect(decoded.entityUndeletes[0].siteId).assertEqual(3);
      expect(decoded.entityUndeletes[1].timestamp).assertEqual(23);
      expect(decodeOperationId('op:14:2')?.timestamp).assertEqual(20);
      expect(decodeOperationId('not-an-operation') === null).assertTrue();
    });

    it('round-trips the original partial-erase history companion as source/remnant replacement', 0, () => {
      const before: SearchSourceElement[] = [{
        elementId: 'op:14:2', kind: 1, payload: new Uint8Array([1, 2, 3]),
      }];
      const after: SearchSourceElement[] = [{
        elementId: 'op:15:2', kind: 1, payload: new Uint8Array([4, 5]),
      }, {
        elementId: 'op:16:2', kind: 1, payload: new Uint8Array([6, 7]),
      }];
      const mutation = decodeOriginalPartialEraseMutation(encodeOriginalPartialEraseMutation(
        { pageMutation: createPageMutation('page-1', 9, 10, before, after),
          replacements: [], beforeGroups: [], afterGroups: [] }));
      expect(mutation.pageMutation.beforeElements.length).assertEqual(1);
      expect(mutation.pageMutation.afterElements.length).assertEqual(2);
      expect(mutation.pageMutation.beforeElements[0].elementId).assertEqual('op:14:2');
      expect(mutation.pageMutation.afterElements[1].elementId).assertEqual('op:16:2');
    });

    it('round-trips a Shape-to-Ink partial-erase page mutation', 0, () => {
      const before: SearchSourceElement[] = [{
        elementId: 'op:20:2', kind: PageElementKind.SHAPE,
        payload: new Uint8Array([1, 2, 3]),
      }];
      const after: SearchSourceElement[] = [{
        elementId: 'op:21:2', kind: PageElementKind.STROKE,
        payload: new Uint8Array([4, 5, 6]),
      }];
      const mutation = decodeOriginalPartialEraseMutation(encodeOriginalPartialEraseMutation({
        pageMutation: createPageMutation('page-1', 10, 11, before, after),
        replacements: [], beforeGroups: [], afterGroups: [],
      }));
      expect(mutation.pageMutation.beforeElements[0].kind).assertEqual(PageElementKind.SHAPE);
      expect(mutation.pageMutation.afterElements[0].kind).assertEqual(PageElementKind.STROKE);
    });

    it('caps original partial-erase history at one type-25 visibility payload', 0, () => {
      const before: SearchSourceElement[] = [];
      for (let index: number = 0; index <= MAX_ORIGINAL_DELETE_ENTITY_COUNT; index++) {
        before.push({
          elementId: `op:${(index + 1).toString(16)}:1`, kind: 1,
          payload: new Uint8Array([index & 0xFF]),
        });
      }
      const oversized = {
        pageMutation: createPageMutation('page-1', 1, 2, before, []),
        replacements: [], beforeGroups: [], afterGroups: [],
      };
      expect(() => validateOriginalPartialEraseMutation(oversized)).assertThrow();
    });

    it('round-trips NPE2 modified and recursively deleted Group snapshots', 0, () => {
      const before: SearchSourceElement[] = [{
        elementId: 'op:a:1', kind: 1, payload: new Uint8Array([1]),
      }, {
        elementId: 'op:14:1', kind: 1, payload: new Uint8Array([2]),
      }];
      const after: SearchSourceElement[] = [before[1]];
      const bytes: Uint8Array = encodeOriginalPartialEraseMutation({
        pageMutation: createPageMutation('page-1', 10, 11, before, after),
        replacements: [{ sourceId: 'op:a:1', remnantIds: [] }],
        beforeGroups: [
          { id: 'op:64:1', timestamp: 100, siteId: 1, members: ['op:a:1'] },
          { id: 'op:c8:1', timestamp: 200, siteId: 1,
            members: ['op:64:1', 'op:14:1'] },
        ],
        afterGroups: [
          { id: 'op:c8:1', timestamp: 200, siteId: 1, members: ['op:14:1'] },
        ],
      });
      expect(bytes[0]).assertEqual(0x4E);
      expect(bytes[3]).assertEqual(0x32);
      const mutation = decodeOriginalPartialEraseMutation(bytes);
      expect(mutation.beforeGroups.length).assertEqual(2);
      expect(mutation.afterGroups.length).assertEqual(1);
      expect(mutation.afterGroups[0].members.join(',')).assertEqual('op:14:1');
      expect(mutation.replacements[0].sourceId).assertEqual('op:a:1');
      mutation.afterGroups[0].members.push('op:b:1');
      expect(() => validateOriginalPartialEraseMutation(mutation)).assertThrow();
    });

    it('rejects a partial-erase Group ID colliding with an unaffected page entity', 0, () => {
      const before: SearchSourceElement[] = [{
        elementId: 'op:a:1', kind: PageElementKind.STROKE,
        payload: new Uint8Array([1]),
      }, {
        elementId: 'op:14:1', kind: PageElementKind.TEXT,
        payload: new Uint8Array([2]),
      }];
      const mutation = {
        pageMutation: createPageMutation('page-1', 11, 12, before, [before[1]]),
        replacements: [{ sourceId: 'op:a:1', remnantIds: [] }],
        beforeGroups: [{ id: 'op:14:1', timestamp: 20, siteId: 1,
          members: ['op:a:1'] }],
        afterGroups: [],
      };
      expect(() => validateOriginalPartialEraseMutation(mutation)).assertThrow();
    });

    it('round-trips original partial eraser as CREATE_INK tool 5', 0, () => {
      const stroke: StrokeElementData = sampleStroke();
      stroke.renderSpec.inkStyle = InkStyle.FIXED_WIDTH;
      stroke.renderSpec.isPartialEraser = true;
      const decoded = decodeOriginalCreateInk(wrap(15, encodeOriginalLocalCreateInk(
        { timestamp: 80, siteId: 7, index: 2 }, stroke)), '1234');
      expect(decoded.tool).assertEqual(5);
      expect(decoded.style).assertEqual(1);
      expect(decoded.width).assertEqual(4.5);
      expect(unsupportedOriginalCreateInkReason(decoded) === null).assertTrue();
    });

    it('round-trips batched original MODIFY_INK render registers', 0, () => {
      const decoded = decodeOriginalModifyInk(wrap(17, encodeOriginalInkRenderRegisters([
        { timestamp: 20, siteId: 2 }, { timestamp: 22, siteId: 4 },
      ], { style: InkStyle.DASH, color: -2146360781, width: 7.5 })));
      expect(decoded.inks.length).assertEqual(2);
      expect(decoded.inks[0].timestamp).assertEqual(20);
      expect(decoded.inks[1].siteId).assertEqual(4);
      expect(decoded.style).assertEqual(2);
      expect(decoded.color).assertEqual(-2146360781);
      expect(decoded.width).assertEqual(7.5);
      expect(decoded.styleMap.present).assertTrue();
      expect(decoded.styleMap.value?.length).assertEqual(0);
      expect(decoded.centerPath === null).assertTrue();
    });

    it('keeps style-map absent for original color-only and width-only updates', 0, () => {
      const color = decodeOriginalModifyInk(wrap(17, encodeOriginalInkRenderRegisters([
        { timestamp: 30, siteId: 3 },
      ], { style: null, color: -16711936, width: null })));
      expect(color.style === null).assertTrue();
      expect(color.color).assertEqual(-16711936);
      expect(color.width === null).assertTrue();
      expect(color.styleMap.present).assertFalse();

      const width = decodeOriginalModifyInk(wrap(17, encodeOriginalInkRenderRegisters([
        { timestamp: 31, siteId: 3 },
      ], { style: null, color: null, width: 6.25 })));
      expect(width.style === null).assertTrue();
      expect(width.color === null).assertTrue();
      expect(width.width).assertEqual(6.25);
      expect(width.styleMap.present).assertFalse();
    });

    it('round-trips original MODIFY_SHAPE color width and nullable fill registers', 0, () => {
      const highlighter = decodeOriginalModifyShape(wrap(19,
        encodeOriginalShapeRenderRegisters([
          { timestamp: 40, siteId: 4 }, { timestamp: 41, siteId: 5 },
        ], { style: 2, color: 0x6B112233, borderWidth: 7.5,
          fillColorPresent: true, fillColor: 0x6B112233, positionLocked: null })));
      expect(highlighter.shapes.length).assertEqual(2);
      expect(highlighter.shapes[0].timestamp).assertEqual(40);
      expect(highlighter.shapes[1].siteId).assertEqual(5);
      expect(highlighter.style).assertEqual(2);
      expect(highlighter.color).assertEqual(0x6B112233);
      expect(highlighter.borderWidth).assertEqual(7.5);
      expect(highlighter.fillColor.present).assertTrue();
      expect(highlighter.fillColor.value).assertEqual(0x6B112233);

      const clear = decodeOriginalModifyShape(wrap(19,
        encodeOriginalShapeRenderRegisters([{ timestamp: 42, siteId: 6 }],
          { style: null, color: null, borderWidth: null,
            fillColorPresent: true, fillColor: null, positionLocked: null })));
      expect(clear.color === null).assertTrue();
      expect(clear.borderWidth === null).assertTrue();
      expect(clear.fillColor.present).assertTrue();
      expect(clear.fillColor.value === null).assertTrue();

      const width = decodeOriginalModifyShape(wrap(19,
        encodeOriginalShapeRenderRegisters([{ timestamp: 43, siteId: 7 }],
          { style: null, color: null, borderWidth: 2.25,
            fillColorPresent: false, fillColor: null, positionLocked: null })));
      expect(width.borderWidth).assertEqual(2.25);
      expect(width.fillColor.present).assertFalse();
      const unlocked = decodeOriginalModifyShape(wrap(19,
        encodeOriginalShapeRenderRegisters([{ timestamp: 44, siteId: 8 }],
          { style: null, color: null, borderWidth: null, fillColorPresent: false,
            fillColor: null, positionLocked: false })));
      expect(unlocked.positionLocked).assertFalse();
      expect(unlocked.style === null).assertTrue();
      expect(() => encodeOriginalShapeRenderRegisters([{ timestamp: 44, siteId: 8 }],
        { style: 0, color: null, borderWidth: null,
          fillColorPresent: false, fillColor: null, positionLocked: null })).assertThrow();
    });

    it('round-trips local LINE POLYGON and rotated ELLIPSE CREATE_SHAPE payloads', 0, () => {
      const line: ShapeElement = {
        id: 'op:64:7', type: ElementType.LINE,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 1, top: 2, right: 9, bottom: 8 },
        start: { x: 1, y: 2 }, controlPoint1: { x: 3, y: 4 },
        controlPoint2: { x: 6, y: 7 }, end: { x: 9, y: 8 },
        arrowHead: ShapeArrowHead.SINGLE, color: 0x6B112233, strokeWidth: 7.5,
        fillColor: null, originalTool: 2, originalStyle: 1,
        originalSmartHighlight: true, originalForce: 0.25,
        originalInkEffects: '18446744073709551615', originalInkEffectsTinted: false,
      };
      const decodedLine = decodeOriginalCreateShape(wrap(18,
        encodeOriginalLocalCreateShape({ timestamp: 80, siteId: 7, index: 2 }, line, 0.6)), '1234');
      const lineDefinition: OriginalLineDefinition = decodedLine.definition as OriginalLineDefinition;
      expect(decodedLine.page.timestamp).assertEqual(80);
      expect(decodedLine.tool).assertEqual(2);
      expect(decodedLine.style).assertEqual(1);
      expect(decodedLine.smartHighlight).assertTrue();
      expect(decodedLine.force).assertEqual(0.25);
      expect(decodedLine.inkEffects).assertEqual('18446744073709551615');
      expect(decodedLine.inkEffectsTinted).assertFalse();
      expect(decodedLine.zIndex).assertEqual('1234');
      expect(decodedLine.fillColor === null).assertTrue();
      expect(decodedLine.positionLocked).assertFalse();
      expect(lineDefinition.controlPoint2?.x).assertEqual(6);
      expect(lineDefinition.arrowHead).assertEqual(1);

      line.fillColor = 0x7F445566;
      line.positionLocked = true;
      const decodedFilledLockedLine = decodeOriginalCreateShape(wrap(18,
        encodeOriginalLocalCreateShape({ timestamp: 80, siteId: 7, index: 2 }, line, null)), '1234');
      expect(decodedFilledLockedLine.fillColor).assertEqual(0x7F445566);
      expect(decodedFilledLockedLine.positionLocked).assertTrue();

      const polygon: ShapeElement = {
        id: 'op:65:7', type: ElementType.POLYGON,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 20, bottom: 10 },
        vertices: [{ x: 0, y: 0 }, { x: 20, y: 0 }, { x: 10, y: 10 }], isClosed: true,
        color: -16777216, strokeWidth: 4, fillColor: null, originalTool: 3, originalStyle: 2,
        originalTapePattern: TapePattern.HEARTS,
      };
      const decodedPolygon = decodeOriginalCreateShape(wrap(18,
        encodeOriginalLocalCreateShape({ timestamp: 80, siteId: 7, index: 2 }, polygon, null)), '1234');
      const polygonDefinition: OriginalPolygonDefinition =
        decodedPolygon.definition as OriginalPolygonDefinition;
      expect(decodedPolygon.style).assertEqual(2);
      expect(decodedPolygon.tapePattern).assertEqual(TapePattern.HEARTS);
      expect(polygonDefinition.points.length).assertEqual(3);
      expect(polygonDefinition.points[2].y).assertEqual(10);

      const ellipse: ShapeElement = {
        id: 'op:66:7', type: ElementType.ELLIPSE,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 90, top: 30, right: 110, bottom: 70 },
        center: { x: 100, y: 50 }, radiusX: 20, radiusY: 10,
        rotationRadians: Math.PI / 2, color: -16777216, strokeWidth: 3,
        fillColor: null, originalTool: 1, originalStyle: 1,
      };
      const decodedEllipse = decodeOriginalCreateShape(wrap(18,
        encodeOriginalLocalCreateShape({ timestamp: 80, siteId: 7, index: 2 }, ellipse, null)), '1234');
      const ellipseDefinition: OriginalEllipseDefinition =
        decodedEllipse.definition as OriginalEllipseDefinition;
      expect(decodedEllipse.originX).assertEqual(110);
      expect(decodedEllipse.originY).assertEqual(30);
      expect(ellipseDefinition.width).assertEqual(40);
      expect(ellipseDefinition.height).assertEqual(20);

      line.fillColor = 0x00112233;
      expect(() => encodeOriginalLocalCreateShape(
        { timestamp: 80, siteId: 7, index: 2 }, line, null)).assertThrow();

      line.fillColor = null;
      line.positionLocked = false;
      line.originalStyle = 0;
      expect(() => encodeOriginalLocalCreateShape(
        { timestamp: 80, siteId: 7, index: 2 }, line, null)).assertThrow();

      line.originalStyle = 1;
      line.originalTapePattern = TapePattern.HEARTS;
      const independentTapeRegister = decodeOriginalCreateShape(wrap(18,
        encodeOriginalLocalCreateShape(
          { timestamp: 80, siteId: 7, index: 2 }, line, null)), '1234');
      expect(independentTapeRegister.tapePattern).assertEqual(TapePattern.HEARTS);
      line.originalTapePattern = null;
      line.originalTool = 1;
      expect(() => encodeOriginalLocalCreateShape(
        { timestamp: 80, siteId: 7, index: 2 }, line, null)).assertThrow();
      line.originalTool = 0;
      line.originalInkEffects = '0';
      expect(() => encodeOriginalLocalCreateShape(
        { timestamp: 80, siteId: 7, index: 2 }, line, null)).assertThrow();
      line.originalInkEffectsTinted = true;
      line.originalInkEffects = '18446744073709551616';
      expect(() => encodeOriginalLocalCreateShape(
        { timestamp: 80, siteId: 7, index: 2 }, line, null)).assertThrow();
    });

    it('round-trips batched original MODIFY_POSITIONS registers', 0, () => {
      const decoded = decodeOriginalModifyPositions(wrap(24, encodeOriginalModifyPositions([{
        target: { timestamp: 20, siteId: 2 },
        pageOrigin: { page: { timestamp: 80, siteId: 7, index: 2 },
          originX: 12.5, originY: -4.25 },
        rotation: { present: true, value: 1.5 },
        scale: { present: true, value: { x: 2.25, y: 0.5 } },
        zIndex: '18446744073709551615',
      }, {
        target: { timestamp: 22, siteId: 4 }, pageOrigin: null,
        rotation: { present: true, value: null },
        scale: { present: true, value: null }, zIndex: null,
      }])));
      expect(decoded.modifications.length).assertEqual(2);
      expect(decoded.modifications[0].target.timestamp).assertEqual(20);
      expect(decoded.modifications[0].pageOrigin?.page.index).assertEqual(2);
      expect(decoded.modifications[0].pageOrigin?.originX).assertEqual(12.5);
      expect(decoded.modifications[0].pageOrigin?.originY).assertEqual(-4.25);
      expect(decoded.modifications[0].rotation.value).assertEqual(1.5);
      expect(decoded.modifications[0].scale.value?.x).assertEqual(2.25);
      expect(decoded.modifications[0].scale.value?.y).assertEqual(0.5);
      expect(decoded.modifications[0].zIndex).assertEqual('18446744073709551615');
      expect(decoded.modifications[1].rotation.present).assertTrue();
      expect(decoded.modifications[1].rotation.value === null).assertTrue();
      expect(decoded.modifications[1].scale.present).assertTrue();
      expect(decoded.modifications[1].scale.value === null).assertTrue();
    });

    it('round-trips ADD_PATH_ELEMENTS actual and estimated attributed appends', 0, () => {
      const stroke: StrokeElementData = sampleStroke();
      const actual: Uint8Array = encodeOriginalInkPathAppend(stroke);
      const estimated: Uint8Array = encodeOriginalInkPathAppend(stroke);
      const decoded = decodeOriginalAddPathElements(wrap(16, encodeOriginalAddPathElementsPayload(
        { timestamp: 90, siteId: 7 }, actual, estimated)));
      expect(decoded.ink.timestamp).assertEqual(90);
      expect(decoded.ink.siteId).assertEqual(7);
      expect(decoded.centerPathElements?.length).assertEqual(actual.length);
      expect(decoded.centerPathEstimatedElements?.length).assertEqual(estimated.length);
      const path = decodeOriginalInkPathAppend(decoded.centerPathElements as Uint8Array,
        stroke.pathPoints[0].position);
      expect(path.pathPoints.length).assertEqual(1);
      expect(path.cubicSegments.length).assertEqual(1);
      expect(path.cubicSegments[0].p1.x).assertEqual(2);
      expect(path.cubicSegments[0].p2.y).assertEqual(4);
      expect(path.cubicSegments[0].p3.x).assertEqual(6);
      expect(path.attributed).assertTrue();
    });

    it('encodes a line-only ADD_PATH_ELEMENTS tail without a MOVE command', 0, () => {
      const stroke: StrokeElementData = sampleStroke();
      stroke.cubicSegments = [];
      const actual: Uint8Array = encodeOriginalInkPathAppend(stroke);
      const decoded = decodeOriginalAddPathElements(wrap(16, encodeOriginalAddPathElementsPayload(
        { timestamp: 90, siteId: 7 }, actual, null)));
      const path = decodeOriginalInkPathAppend(decoded.centerPathElements as Uint8Array,
        stroke.pathPoints[0].position);
      expect(path.pathPoints.length).assertEqual(1);
      expect(path.cubicSegments.length).assertEqual(1);
      expect(path.endPoint.x).assertEqual(6);
      expect(path.endPoint.y).assertEqual(5);
      expect(decoded.centerPathEstimatedElements === null).assertTrue();
    });

    it('wraps durable and transient payload tables in canonical uq9 metadata', 0, () => {
      const payload: Uint8Array = encodeOriginalAddPathElementsPayload(
        { timestamp: 90, siteId: 7 }, encodeOriginalInkPathAppend(sampleStroke()), null);
      const durable: Uint8Array = wrap(16, payload);
      const durableEnvelope = parseOriginalOperationEnvelope(durable);
      expect(durableEnvelope.timestamp).assertEqual(100);
      expect(durableEnvelope.siteId).assertEqual(7);
      expect(durableEnvelope.clientTime).assertEqual('1234');
      expect(durableEnvelope.serverTime === null).assertTrue();
      expect(durableEnvelope.payloadType).assertEqual(16);
      expect(() => parseOriginalSyncedOperationEnvelope(durable)).assertThrow();
      expect(decodeOriginalTransientInteractionMetadata(
        OriginalFlatBufferTableReader.fromRoot(durable)) === null).assertTrue();

      const transient: Uint8Array = encodeOriginalOperationEnvelope({
        identity: { timestamp: 101, siteId: 7 }, clientTime: '1235', serverTime: null,
        audioTime: '88', payloadType: 16,
        transientInteractionId: { timestamp: 90, siteId: 7 },
      }, payload);
      const transientEnvelope = parseOriginalOperationEnvelope(transient);
      expect(transientEnvelope.audioTime).assertEqual('88');
      const metadata = decodeOriginalTransientInteractionMetadata(
        OriginalFlatBufferTableReader.fromRoot(transient));
      expect(metadata?.interactionId.timestamp).assertEqual(90);
      expect(metadata?.interactionId.siteId).assertEqual(7);
    });

    it('round-trips transient interaction end replacement metadata', 0, () => {
      const interaction = { timestamp: 90, siteId: 7 };
      const end: Uint8Array = encodeOriginalOperationEnvelope({
        identity: { timestamp: 102, siteId: 7 }, clientTime: '1236', serverTime: null,
        audioTime: null, payloadType: 26, transientInteractionId: interaction,
      }, encodeOriginalTransientInteractionEndedPayload(
        interaction, { timestamp: 100, siteId: 7 }));
      const decoded = decodeOriginalTransientInteractionEnded(end);
      expect(decoded.interactionId.timestamp).assertEqual(90);
      expect(decoded.replacedByOp?.timestamp).assertEqual(100);
      expect(decoded.replacedByOp?.siteId).assertEqual(7);
    });
  });
}

function wrap(payloadType: number, payload: Uint8Array): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: 100, siteId: 7 }, clientTime: '1234', serverTime: null,
    audioTime: null, payloadType: payloadType,
  }, payload);
}

function sampleStroke(): StrokeElementData {
  return {
    id: 'op:5a:7',
    pathPoints: [
      { position: { x: 1, y: 1 }, widthFactor: 0.5, pressure: 0.4,
        altitudeAngleRadians: 0.8, azimuthUnitX: 1, azimuthUnitY: 0 },
      { position: { x: 6, y: 5 }, widthFactor: 0.9, pressure: 0.8,
        altitudeAngleRadians: 1.1, azimuthUnitX: 0, azimuthUnitY: 1 },
    ],
    cubicSegments: [{
      p0: { x: 1, y: 1 }, p1: { x: 2, y: 3 },
      p2: { x: 4, y: 4 }, p3: { x: 6, y: 5 },
    }],
    splatPoints: [],
    renderSpec: { color: -2146360781, brushWidth: 4.5,
      inkStyle: InkStyle.VARIABLE_WIDTH, isHighlighter: false, isPencil: false },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 7, bottom: 6 }, maskPath: [],
    originalCreate: {
      timestamp: 90, siteId: 7, clientTime: 1234,
      pageTimestamp: 80, pageSiteId: 7, pageIndex: 2,
      pencilSeed: 1234,
    },
    isFinished: true,
  };
}
