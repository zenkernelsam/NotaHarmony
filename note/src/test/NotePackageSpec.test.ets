import { describe, expect, it } from '@ohos/hypium';
import {
  isSupportedPageElementKind, isValidPageElement, NOTE_MAX_PAGE_COUNT, parseManifest, parsePage, parsePageElement,
} from '../main/ets/data/NotePackageSpec';
import { ElementType } from '../main/ets/core/model/ElementTypes';

export default function notePackageSpecTest() {
  describe('NotePackageSpec', () => {
    it('accepts every element kind emitted by the package exporter', 0, () => {
      expect(isSupportedPageElementKind('stroke')).assertTrue();
      expect(isSupportedPageElementKind('text')).assertTrue();
      expect(isSupportedPageElementKind('shape')).assertTrue();
      expect(isSupportedPageElementKind('unknown')).assertFalse();
    });

    it('rejects unsafe manifest counts and invalid page enums', 0, () => {
      const manifest = { format: 'nota.note', version: 1, title: 'n', noteId: 'id',
        createdAt: 0, updatedAt: 0, pageCount: NOTE_MAX_PAGE_COUNT + 1,
        appVersion: '1', source: 'NotaHarmony' };
      expect(parseManifest(JSON.stringify(manifest)) === null).assertTrue();
      manifest.pageCount = 1.5;
      expect(parseManifest(JSON.stringify(manifest)) === null).assertTrue();
      const page = { pageId: 'p', pageIndex: 0, paperSize: 8, paperTemplate: 0,
        orientation: 0, elements: [] };
      expect(parsePage(JSON.stringify(page)) === null).assertTrue();
      page.paperSize = 1;
      page.orientation = 2;
      expect(parsePage(JSON.stringify(page)) === null).assertTrue();
    });

    it('validates semantic shape payloads instead of trusting kind alone', 0, () => {
      const shape = {
        kind: 'shape', data: {
          id: 'ellipse', type: ElementType.ELLIPSE,
          transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
          bounds: { left: 0, top: 0, right: 20, bottom: 10 },
          center: { x: 10, y: 5 }, radiusX: 10, radiusY: 5, rotationRadians: 0,
          color: -16777216, strokeWidth: 2, fillColor: null,
        },
      };
      expect(isValidPageElement(shape)).assertTrue();
      shape.data.transform = [1, 0, 0];
      expect(isValidPageElement(shape)).assertFalse();
    });

    it('rejects truncated stroke and text payloads', 0, () => {
      expect(isValidPageElement({ kind: 'stroke', data: { id: 's' } })).assertFalse();
      expect(isValidPageElement({ kind: 'text', data: { id: 't', richText: 'lost' } })).assertFalse();
      expect(isValidPageElement({ kind: 'shape', data: { id: 'x', type: 99 } })).assertFalse();
    });

    it('rejects null nested stroke members without throwing', 0, () => {
      const broken = { kind: 'stroke', data: {
        id: 'broken', pathPoints: [null], cubicSegments: [null], splatPoints: [null],
        renderSpec: { color: 0, brushWidth: 1, inkStyle: 0,
          isHighlighter: false, isPencil: false },
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 0, bottom: 0 }, maskPath: [], isFinished: true,
      } };
      expect(parsePageElement(broken) === null).assertTrue();
    });

    it('accepts stroke and text payloads emitted by persistence', 0, () => {
      const base = {
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 10, bottom: 10 },
      };
      const stroke = { kind: 'stroke', data: {
        id: 's', pathPoints: [{ position: { x: 0, y: 0 }, widthFactor: 1,
          pressure: -1, altitudeAngleRadians: Math.PI / 2, azimuthUnitX: 1, azimuthUnitY: 0 }],
        cubicSegments: [], splatPoints: [], renderSpec: { color: -16777216, brushWidth: 2,
          inkStyle: 0, isHighlighter: false, isPencil: false },
        transform: base.transform, bounds: base.bounds, maskPath: [], isFinished: true,
      } };
      const text = { kind: 'text', data: {
        id: 't', type: ElementType.TEXT, transform: base.transform, bounds: base.bounds,
        richText: 'text', textOrigin: { x: 0, y: 0 }, blockWidth: 10, blockHeight: 10,
        rotationRadians: 0, contentLeftInset: 0, contentTopInset: 0,
        fontSize: 12, fontColor: -16777216,
      } };
      expect(isValidPageElement(stroke)).assertTrue();
      expect(isValidPageElement(text)).assertTrue();
    });

    it('normalizes legacy v1 stroke attributes before validation', 0, () => {
      const legacy = { kind: 'stroke', data: {
        id: 'legacy', pathPoints: [{ position: { x: 0, y: 0 }, widthFactor: 1 }],
        cubicSegments: [], splatPoints: [], renderSpec: { color: 0, brushWidth: 1,
          inkStyle: 0, isHighlighter: false, isPencil: false },
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 0, bottom: 0 }, maskPath: [], isFinished: true,
      } };
      expect(parsePageElement(legacy) !== null).assertTrue();
      expect(legacy.data.pathPoints[0].pressure).assertEqual(-1);
      expect(legacy.data.pathPoints[0].altitudeAngleRadians).assertEqual(Math.PI / 2);
      expect(legacy.data.pathPoints[0].azimuthUnitX).assertEqual(1);
      expect(legacy.data.pathPoints[0].azimuthUnitY).assertEqual(0);
    });
  });
}
