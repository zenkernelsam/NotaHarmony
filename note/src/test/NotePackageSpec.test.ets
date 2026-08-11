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
      expect(isSupportedPageElementKind('image')).assertTrue();
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

    it('validates complete image metadata without truncating uint64 hash words', 0, () => {
      const bits: string[] = ['0', '1', '2', '3', '4', '5', '6', '18446744073709551615'];
      const image = { kind: 'image', data: {
        id: 'image', type: ElementType.IMAGE,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 100, bottom: 50 },
        assetHash: bits.join(':'), assetHashBits: bits, fileName: '图片.png', mimeType: 'image/png',
        fileSize: 4294967295, intrinsicWidth: 200, intrinsicHeight: 100,
        cropRect: { left: -5, top: 2, right: 195, bottom: 92 },
        blockWidth: 100, blockHeight: 50, rotationRadians: 0, corner: 1, textWrap: 0,
        enableCaption: false, webUrl: 'https://example.test/image',
        imageFlippedHorizontally: true, imageFlippedVertically: false, positionLocked: true,
      } };
      expect(isValidPageElement(image)).assertTrue();
      image.data.assetHash = '0:1:2:3:4:5:6:7';
      expect(isValidPageElement(image)).assertFalse();
      image.data.assetHash = bits.join(':');
      image.data.assetHashBits[7] = '18446744073709551616';
      expect(isValidPageElement(image)).assertFalse();
    });

    it('preserves optional custom page geometry and original paper background', 0, () => {
      const page = { pageId: 'paper', pageIndex: 0, paperSize: 5, paperTemplate: 2,
        orientation: 1, widthMm: 279.4, heightMm: 215.9, elements: [],
        background: { schemaVersion: 1, rotationRadians: Math.PI / 2,
          sourceWidthPt: 612, sourceHeightPt: 792,
          margins: { topPt: 10, bottomPt: 10, leftPt: 12, rightPt: 12 },
          paper: { flair: 2, flairSpacingPt: 18, flairBleeds: true, flairCentered: true,
            colorR: 250, colorG: 249, colorB: 248, colorA: 255, legacyPaperIndex: 7 } } };
      const parsed = parsePage(JSON.stringify(page));
      expect(parsed === null).assertFalse();
      expect(parsed === null ? 0 : parsed.widthMm).assertEqual(279.4);
      page.originalPageInAsset = 0xFFFFFFFF;
      expect(parsePage(JSON.stringify(page))?.originalPageInAsset).assertEqual(0xFFFFFFFF);
      page.originalPageInAsset = -1;
      expect(parsePage(JSON.stringify(page)) === null).assertTrue();
      page.originalPageInAsset = 0;
      page.heightMm = 0;
      expect(parsePage(JSON.stringify(page)) === null).assertTrue();
      page.heightMm = 215.9;
      page.background.paper.colorA = 128;
      expect(parsePage(JSON.stringify(page)) === null).assertTrue();
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
          inkStyle: 0, isHighlighter: false, isPencil: false,
          inkEffects: '18446744073709551615', inkEffectsTinted: false,
          inkEffectPhase: -3.25 },
        transform: base.transform, bounds: base.bounds, maskPath: [], isFinished: true,
      } };
      const text = { kind: 'text', data: {
        id: 't', type: ElementType.TEXT, transform: base.transform, bounds: base.bounds,
        richText: 'text', textOrigin: { x: 0, y: 0 }, blockWidth: 10, blockHeight: 10,
        rotationRadians: 0, contentLeftInset: 0, contentTopInset: 0,
        fontSize: 12, fontColor: -16777216, characterStyleRuns: undefined,
        paragraphStyleRuns: undefined,
        originalCreate: { timestamp: 10, siteId: 7, clientTime: 20,
          pageTimestamp: 30, pageSiteId: 8, pageIndex: 1, pencilSeed: 0 },
      } };
      expect(isValidPageElement(stroke)).assertTrue();
      stroke.data.renderSpec.inkEffects = '18446744073709551616';
      expect(isValidPageElement(stroke)).assertFalse();
      stroke.data.renderSpec.inkEffects = '3';
      stroke.data.renderSpec.inkEffectPhase = Number.POSITIVE_INFINITY;
      expect(isValidPageElement(stroke)).assertFalse();
      stroke.data.renderSpec.inkEffectPhase = 7.5;
      expect(isValidPageElement(stroke)).assertTrue();
      expect(isValidPageElement(text)).assertTrue();
      text.data.characterStyleRuns = [{ start: 0, end: 4,
        style: { bold: true, foregroundColor: -16777216 } }];
      text.data.paragraphStyleRuns = [{ start: 0, end: 4,
        style: { alignment: 2, lineSpacing: 1.5 } }];
      expect(isValidPageElement(text)).assertTrue();
      text.data.characterStyleRuns = [{ start: 0, end: 5, style: { bold: true } }];
      expect(isValidPageElement(text)).assertFalse();
      text.data.characterStyleRuns = [{ start: 0, end: 2, style: { bold: true } },
        { start: 1, end: 4, style: { italic: true } }];
      expect(isValidPageElement(text)).assertFalse();
      text.data.characterStyleRuns = [{ start: 0, end: 4, style: { bold: 'yes' } }];
      expect(isValidPageElement(text)).assertFalse();
      text.data.characterStyleRuns = [{ start: 0, end: 4, style: { superscript: true,
        subscript: true } }];
      expect(isValidPageElement(text)).assertFalse();
      text.data.characterStyleRuns = [];
      text.data.originalCreate.siteId = 65536;
      expect(isValidPageElement(text)).assertFalse();
      text.data.originalCreate.siteId = 7;
      text.data.originalCreate.timestamp = -1;
      expect(isValidPageElement(text)).assertFalse();
      text.data.originalCreate.timestamp = 10;
      text.data.originalCreate.pencilSeed = 0.5;
      expect(isValidPageElement(text)).assertFalse();
      text.data.originalCreate.pencilSeed = 0;
      expect(isValidPageElement(text)).assertTrue();

      const shape = { kind: 'shape', data: {
        id: 'shape-text', type: ElementType.ELLIPSE, transform: base.transform,
        bounds: base.bounds, center: { x: 5, y: 5 }, radiusX: 5, radiusY: 5,
        rotationRadians: 0, color: -16777216, strokeWidth: 1, fillColor: null,
        richText: 'A😀', characterStyleRuns: [{ start: 1, end: 2,
          style: { italic: true } }], paragraphStyleRuns: [],
      } };
      expect(isValidPageElement(shape)).assertTrue();
      shape.data.characterStyleRuns = [{ start: 1, end: 3, style: { italic: true } }];
      expect(isValidPageElement(shape)).assertFalse();
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
