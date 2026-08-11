import { describe, expect, it } from '@ohos/hypium';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import { decodeOriginalCreateInk } from '../main/ets/data/OriginalCreateInkOperation';
import { encodeOriginalLocalCreateInk } from
  '../main/ets/data/OriginalCreateInkPayloadEncoder';
import { decodeOperationId } from '../main/ets/data/OperationIdentity';
import { encodeOriginalEntityVisibility } from
  '../main/ets/data/OriginalDeleteEntitiesPayloadEncoder';
import { decodeOriginalDeleteEntities } from '../main/ets/data/OriginalDeleteEntitiesOperation';

export default function originalCreateInkPayloadEncoderTest() {
  describe('OriginalCreateInkPayloadEncoder', () => {
    it('round-trips a BITS_32 cubic local pen through dm2', 0, () => {
      const stroke: StrokeElementData = sampleStroke();
      const decoded = decodeOriginalCreateInk(encodeOriginalLocalCreateInk(
        { timestamp: 80, siteId: 7, index: 2 }, stroke), '1234');
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
      const pencil = decodeOriginalCreateInk(encodeOriginalLocalCreateInk(
        { timestamp: 80, siteId: 7, index: 2 }, stroke), '1234');
      expect(pencil.tool).assertEqual(1);
      expect(pencil.styleMap[0].backingPencilSeed).assertEqual(-1234);
    });

    it('encodes batched entity delete and undelete vectors without changing identity', 0, () => {
      const decoded = decodeOriginalDeleteEntities(encodeOriginalEntityVisibility(
        [{ timestamp: 20, siteId: 2 }, { timestamp: 22, siteId: 4 },
          { timestamp: 24, siteId: 6 }],
        [{ timestamp: 21, siteId: 3 }, { timestamp: 23, siteId: 5 }]));
      expect(decoded.entityDeletes.length).assertEqual(3);
      expect(decoded.entityDeletes[0].timestamp).assertEqual(20);
      expect(decoded.entityDeletes[2].siteId).assertEqual(6);
      expect(decoded.entityUndeletes.length).assertEqual(2);
      expect(decoded.entityUndeletes[0].siteId).assertEqual(3);
      expect(decoded.entityUndeletes[1].timestamp).assertEqual(23);
      expect(decodeOperationId('op:14:2')?.timestamp).assertEqual(20);
      expect(decodeOperationId('not-an-operation') === null).assertTrue();
    });
  });
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
