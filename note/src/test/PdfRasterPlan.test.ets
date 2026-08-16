import { describe, it, expect } from '@ohos/hypium';
import {
  buildPdfRasterPlan, PDF_RASTER_MAX_PIXELS, PDF_RASTER_MAX_SIDE,
  PdfRasterPlan, PdfRasterRequest, pdfRasterPlanCovers,
} from '../main/ets/rendering/PdfRasterPlan';

function request(paperWidth: number, paperHeight: number, rotationRadians: number,
  left: number, top: number, right: number, bottom: number,
  outputScale: number = 1, overscanRatio: number = 0): PdfRasterRequest {
  return {
    paperWidth: paperWidth,
    paperHeight: paperHeight,
    visiblePageRect: { left: left, top: top, right: right, bottom: bottom },
    outputScale: outputScale,
    rotationRadians: rotationRadians,
    margins: null,
    overscanRatio: overscanRatio,
  };
}

function requirePlan(value: PdfRasterPlan | null): PdfRasterPlan {
  expect(value !== null).assertTrue();
  if (value === null) {
    throw new Error('expected a PDF raster plan');
  }
  return value;
}

function near(left: number, right: number): boolean {
  return Math.abs(left - right) < 0.000001;
}

export default function pdfRasterPlanTest() {
  describe('PdfRasterPlan', () => {
    it('maps a margin-bounded full page to the complete PDF matrix', 0, () => {
      const value: PdfRasterRequest = request(800, 1000, 0, 0, 0, 800, 1000, 0.5);
      value.margins = { topPt: 36, bottomPt: 36, leftPt: 36, rightPt: 36 };
      const plan: PdfRasterPlan = requirePlan(buildPdfRasterPlan(value, 600, 800));
      expect(near(plan.destinationRect.left, 48)).assertTrue();
      expect(near(plan.destinationRect.top, 48)).assertTrue();
      expect(near(plan.destinationRect.right, 752)).assertTrue();
      expect(near(plan.destinationRect.bottom, 952)).assertTrue();
      expect(near(plan.matrixX, 0)).assertTrue();
      expect(near(plan.matrixY, 0)).assertTrue();
      expect(near(plan.matrixWidth, 600)).assertTrue();
      expect(near(plan.matrixHeight, 800)).assertTrue();
      expect(plan.bitmapWidth).assertEqual(352);
      expect(plan.bitmapHeight).assertEqual(452);
    });

    it('converts top-origin visible halves to bottom-origin PDF y values', 0, () => {
      const top: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        request(800, 1000, 0, 0, 0, 800, 499), 600, 800));
      const bottom: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        request(800, 1000, 0, 0, 501, 800, 1000), 600, 800));
      expect(near(top.destinationRect.bottom, 500)).assertTrue();
      expect(near(top.matrixY, 400)).assertTrue();
      expect(near(top.matrixHeight, 400)).assertTrue();
      expect(near(bottom.destinationRect.top, 500)).assertTrue();
      expect(near(bottom.matrixY, 0)).assertTrue();
      expect(near(bottom.matrixHeight, 400)).assertTrue();
    });

    it('inverse-maps all cardinal page rotations before PDF clipping', 0, () => {
      const zero: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        request(800, 1000, 0, 101, 201, 299, 399), 800, 1000));
      expect(near(zero.destinationRect.left, 100)).assertTrue();
      expect(near(zero.destinationRect.top, 200)).assertTrue();
      expect(near(zero.destinationRect.right, 300)).assertTrue();
      expect(near(zero.destinationRect.bottom, 400)).assertTrue();

      const ninety: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        request(1000, 800, Math.PI / 2, 101, 201, 299, 399), 800, 1000));
      expect(near(ninety.destinationRect.left, 200)).assertTrue();
      expect(near(ninety.destinationRect.top, 700)).assertTrue();
      expect(near(ninety.destinationRect.right, 400)).assertTrue();
      expect(near(ninety.destinationRect.bottom, 900)).assertTrue();

      const oneEighty: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        request(800, 1000, Math.PI, 101, 201, 299, 399), 800, 1000));
      expect(near(oneEighty.destinationRect.left, 500)).assertTrue();
      expect(near(oneEighty.destinationRect.top, 600)).assertTrue();
      expect(near(oneEighty.destinationRect.right, 700)).assertTrue();
      expect(near(oneEighty.destinationRect.bottom, 800)).assertTrue();

      const twoSeventy: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        request(1000, 800, Math.PI * 3 / 2, 101, 201, 299, 399), 800, 1000));
      expect(near(twoSeventy.destinationRect.left, 400)).assertTrue();
      expect(near(twoSeventy.destinationRect.top, 100)).assertTrue();
      expect(near(twoSeventy.destinationRect.right, 600)).assertTrue();
      expect(near(twoSeventy.destinationRect.bottom, 300)).assertTrue();
    });

    it('bounds an 8x A3 request by side and pixel budgets', 0, () => {
      const plan: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        request(1123, 1588, 0, 0, 0, 1123, 1588, 8), 842, 1191));
      expect(plan.bitmapWidth <= PDF_RASTER_MAX_SIDE).assertTrue();
      expect(plan.bitmapHeight <= PDF_RASTER_MAX_SIDE).assertTrue();
      expect(plan.pixelCount <= PDF_RASTER_MAX_PIXELS).assertTrue();
      expect(plan.rasterScale < 8).assertTrue();
    });

    it('uses the original positive round rule for output bitmap dimensions', 0, () => {
      const plan: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        request(101, 101, 0, 0, 0, 101, 101, 0.5), 101, 101));
      expect(plan.bitmapWidth).assertEqual(51);
      expect(plan.bitmapHeight).assertEqual(51);
    });

    it('reuses overscan for small pans and lower scale but refreshes outside it', 0, () => {
      const initial: PdfRasterRequest = request(1200, 1600, 0, 100, 100, 500, 500, 3, 0.25);
      const plan: PdfRasterPlan = requirePlan(buildPdfRasterPlan(initial, 900, 1200));
      const smallPan: PdfRasterRequest = request(1200, 1600, 0, 150, 150, 550, 550, 2.5, 0.25);
      const largePan: PdfRasterRequest = request(1200, 1600, 0, 500, 500, 900, 900, 2.5, 0.25);
      const zoomIn: PdfRasterRequest = request(1200, 1600, 0, 150, 150, 550, 550, 3.5, 0.25);
      expect(pdfRasterPlanCovers(plan, smallPan)).assertTrue();
      expect(pdfRasterPlanCovers(plan, largePan)).assertFalse();
      expect(pdfRasterPlanCovers(plan, zoomIn)).assertFalse();
    });

    it('rerasterizes a budget-limited overview when a detail view can afford more scale', 0, () => {
      const overview: PdfRasterRequest = request(
        1200, 1600, 0, 0, 0, 1200, 1600, 8, 0.25);
      const overviewPlan: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        overview, 900, 1200));
      const detail: PdfRasterRequest = request(
        1200, 1600, 0, 100, 100, 300, 300, 8, 0.25);
      expect(overviewPlan.rasterScale < detail.outputScale).assertTrue();
      expect(pdfRasterPlanCovers(overviewPlan, overview)).assertTrue();
      expect(pdfRasterPlanCovers(overviewPlan, detail)).assertFalse();

      const detailPlan: PdfRasterPlan = requirePlan(buildPdfRasterPlan(
        detail, 900, 1200));
      expect(near(detailPlan.rasterScale, 8)).assertTrue();
      expect(pdfRasterPlanCovers(detailPlan, detail)).assertTrue();
    });

    it('returns no raster for a page outside the viewport', 0, () => {
      const plan: PdfRasterPlan | null = buildPdfRasterPlan(
        request(800, 1000, 0, 900, 100, 1200, 500), 600, 800);
      expect(plan === null).assertTrue();
    });

    it('treats legal zero-area margins as empty and rejects malformed margins', 0, () => {
      const empty: PdfRasterRequest = request(800, 1000, 0, 0, 0, 800, 1000);
      empty.margins = { topPt: 0, bottomPt: 0, leftPt: 300, rightPt: 300 };
      expect(buildPdfRasterPlan(empty, 600, 800) === null).assertTrue();

      const malformed: PdfRasterRequest = request(800, 1000, 0, 0, 0, 800, 1000);
      malformed.margins = { topPt: -1, bottomPt: 0, leftPt: 0, rightPt: 0 };
      let rejected: boolean = false;
      try {
        buildPdfRasterPlan(malformed, 600, 800);
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });
  });
}
