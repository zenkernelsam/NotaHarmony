import { describe, it, expect } from '@ohos/hypium';
import {
  MAX_PAGE_CACHE_PIXELS, MAX_PAGE_CACHE_SIDE, PAGE_UNITS_PER_MM, PagePixelSize, pagePixelSize,
} from '../main/ets/core/model/PageCoordinateSpace';
import { CanvasViewport } from '../main/ets/rendering/CanvasViewport';
import { Point2D } from '../main/ets/core/model/GeometryTypes';

export default function pageCoordinateSpaceTest() {
  describe('PageCoordinateSpace', () => {
    it('bounds every standard page cache while rejecting oversized metadata', 0, () => {
      const standardPages: number[][] = [
        [297, 420], [210, 297], [148, 210], [105, 148], [74, 105],
        [215.9, 279.4], [215.9, 355.6], [279.4, 431.8],
      ];
      for (const dimensions of standardPages) {
        const portrait: PagePixelSize = pagePixelSize(dimensions[0], dimensions[1]);
        const landscape: PagePixelSize = pagePixelSize(dimensions[1], dimensions[0]);
        expect(portrait.pixels <= MAX_PAGE_CACHE_PIXELS).assertTrue();
        expect(portrait.width <= MAX_PAGE_CACHE_SIDE).assertTrue();
        expect(portrait.height <= MAX_PAGE_CACHE_SIDE).assertTrue();
        expect(landscape.pixels).assertEqual(portrait.pixels);
      }
      const a3: PagePixelSize = pagePixelSize(297, 420);
      expect(a3.width).assertEqual(Math.ceil(297 * PAGE_UNITS_PER_MM));
      expect(a3.height).assertEqual(Math.ceil(420 * PAGE_UNITS_PER_MM));
      expect(a3.pixels).assertEqual(1783324);
      expect(a3.rgbaBytes).assertEqual(7133296);
      expect(a3.pixels < MAX_PAGE_CACHE_PIXELS).assertTrue();

      let rejected: boolean = false;
      try {
        pagePixelSize(10000, 10000);
      } catch (e) {
        rejected = true;
      }
      expect(rejected).assertTrue();

      rejected = false;
      try {
        pagePixelSize(1, 1000);
      } catch (e) {
        rejected = true;
      }
      expect(rejected).assertTrue();

      rejected = false;
      try {
        pagePixelSize(0, 297);
      } catch (e) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('round-trips one page control point at 25, 100, 400 and original 1000 percent', 0, () => {
      const viewport: CanvasViewport = new CanvasViewport();
      const pagePoint: Point2D = { x: 321.25, y: 654.75 };
      const zooms: number[] = [0.25, 1, 4, 10];
      for (const zoom of zooms) {
        viewport.setZoomRaw(zoom);
        viewport.setScroll(-173.5, 82.25);
        const screen: Point2D = viewport.canvasToScreen(pagePoint.x, pagePoint.y);
        const restored: Point2D = viewport.screenToCanvas(screen.x, screen.y);
        expect(Math.abs(restored.x - pagePoint.x) < 1e-10).assertTrue();
        expect(Math.abs(restored.y - pagePoint.y) < 1e-10).assertTrue();
      }
    });

    it('keeps the page point under a zoom anchor fixed after large panning', 0, () => {
      const viewport: CanvasViewport = new CanvasViewport();
      viewport.setZoomRaw(0.25);
      viewport.setScroll(-1200, 730);
      const anchor: Point2D = { x: 413, y: 277 };
      const before: Point2D = viewport.screenToCanvas(anchor.x, anchor.y);
      viewport.zoomAt(anchor.x, anchor.y, 40);
      const after: Point2D = viewport.screenToCanvas(anchor.x, anchor.y);
      expect(viewport.zoom).assertEqual(10);
      expect(Math.abs(after.x - before.x) < 1e-10).assertTrue();
      expect(Math.abs(after.y - before.y) < 1e-10).assertTrue();
    });
  });
}
