import { describe, it, expect } from '@ohos/hypium';
import { Point2D } from '../main/ets/core/model/GeometryTypes';
import {
  ORIGINAL_VIEWPORT_MAX_ZOOM, ORIGINAL_VIEWPORT_MIN_ZOOM,
} from '../main/ets/core/model/NoteTypes';
import { CanvasViewport, CumulativeGestureTracker } from '../main/ets/rendering/CanvasViewport';

export default function canvasViewportTest() {
  describe('CanvasViewport', () => {
    it('round-trips 1000 deterministic points across zoom and large scroll ranges', 0, () => {
      const viewport: CanvasViewport = new CanvasViewport();
      let seed: number = 20260809;
      const random = (): number => {
        seed = (seed * 1664525 + 1013904223) >>> 0;
        return seed / 4294967296;
      };
      for (let i: number = 0; i < 1000; i++) {
        viewport.setZoomRaw(ORIGINAL_VIEWPORT_MIN_ZOOM +
          random() * (ORIGINAL_VIEWPORT_MAX_ZOOM - ORIGINAL_VIEWPORT_MIN_ZOOM));
        viewport.setScroll(-5000 + random() * 10000, -5000 + random() * 10000);
        const page: Point2D = { x: -1000 + random() * 4000, y: -1000 + random() * 4000 };
        const screen: Point2D = viewport.canvasToScreen(page.x, page.y);
        const restored: Point2D = viewport.screenToCanvas(screen.x, screen.y);
        expect(Math.abs(restored.x - page.x) < 0.000001).assertTrue();
        expect(Math.abs(restored.y - page.y) < 0.000001).assertTrue();
      }
    });

    it('keeps random screen anchors within 0.5 pixels while zooming', 0, () => {
      const viewport: CanvasViewport = new CanvasViewport();
      for (let i: number = 0; i < 1000; i++) {
        viewport.setZoomRaw(ORIGINAL_VIEWPORT_MIN_ZOOM + (i % 40) * 0.25);
        viewport.setScroll(-1500 + i * 1.7, 900 - i * 0.8);
        const anchor: Point2D = { x: (i * 97) % 2048, y: (i * 53) % 1536 };
        const pageBefore: Point2D = viewport.screenToCanvas(anchor.x, anchor.y);
        viewport.zoomAt(anchor.x, anchor.y, i % 2 === 0 ? 1.1 : 0.9);
        const screenAfter: Point2D = viewport.canvasToScreen(pageBefore.x, pageBefore.y);
        expect(Math.abs(screenAfter.x - anchor.x) < 0.5).assertTrue();
        expect(Math.abs(screenAfter.y - anchor.y) < 0.5).assertTrue();
      }
    });

    it('rejects corrupt persisted values without poisoning a valid viewport', 0, () => {
      const viewport: CanvasViewport = new CanvasViewport();
      viewport.setZoomRaw(2);
      viewport.setScroll(30, 40);
      expect(viewport.setZoomRaw(Number.NaN)).assertFalse();
      expect(viewport.setZoomRaw(Number.POSITIVE_INFINITY)).assertFalse();
      expect(viewport.setZoomRaw(Number.NEGATIVE_INFINITY)).assertFalse();
      expect(viewport.setZoomRaw(ORIGINAL_VIEWPORT_MIN_ZOOM)).assertTrue();
      expect(viewport.setZoomRaw(ORIGINAL_VIEWPORT_MIN_ZOOM - 0.01)).assertFalse();
      expect(viewport.setZoomRaw(ORIGINAL_VIEWPORT_MAX_ZOOM)).assertTrue();
      expect(viewport.setZoomRaw(ORIGINAL_VIEWPORT_MAX_ZOOM + 0.01)).assertFalse();
      expect(viewport.setScroll(Number.NaN, 10)).assertFalse();
      viewport.zoomAt(20, 20, Number.POSITIVE_INFINITY);
      viewport.panBy(Number.NaN, 5);
      expect(viewport.zoom).assertEqual(ORIGINAL_VIEWPORT_MAX_ZOOM);
      expect(viewport.scrollX).assertEqual(30);
      expect(viewport.scrollY).assertEqual(40);
    });

    it('uses additive toolbar steps while preserving the viewport-center anchor', 0, () => {
      const viewport: CanvasViewport = new CanvasViewport();
      viewport.setScroll(-80, 45);
      const anchor: Point2D = { x: 600, y: 400 };
      const pageBefore: Point2D = viewport.screenToCanvas(anchor.x, anchor.y);
      viewport.stepZoomAt(anchor.x, anchor.y, 0.25);
      expect(viewport.zoom).assertEqual(1.25);
      viewport.stepZoomAt(anchor.x, anchor.y, 0.25);
      expect(viewport.zoom).assertEqual(1.5);
      viewport.stepZoomAt(anchor.x, anchor.y, 0.25);
      expect(viewport.zoom).assertEqual(1.75);
      const screenAfter: Point2D = viewport.canvasToScreen(pageBefore.x, pageBefore.y);
      expect(Math.abs(screenAfter.x - anchor.x) < 0.000001).assertTrue();
      expect(Math.abs(screenAfter.y - anchor.y) < 0.000001).assertTrue();
      viewport.stepZoomAt(anchor.x, anchor.y, -0.25);
      expect(viewport.zoom).assertEqual(1.5);

      viewport.setZoomRaw(ORIGINAL_VIEWPORT_MAX_ZOOM);
      viewport.stepZoomAt(anchor.x, anchor.y, 0.25);
      expect(viewport.zoom).assertEqual(ORIGINAL_VIEWPORT_MAX_ZOOM);
      viewport.setZoomRaw(ORIGINAL_VIEWPORT_MIN_ZOOM);
      viewport.stepZoomAt(anchor.x, anchor.y, -0.25);
      expect(viewport.zoom).assertEqual(ORIGINAL_VIEWPORT_MIN_ZOOM);
    });

    it('converts cumulative pinch and pan values to frame deltas and resets after cancel', 0, () => {
      const tracker: CumulativeGestureTracker = new CumulativeGestureTracker();
      expect(tracker.nextScaleFactor(1.2)).assertEqual(1.2);
      expect(Math.abs(tracker.nextScaleFactor(1.5) - 1.25) < 0.000001).assertTrue();
      let delta: Point2D = tracker.nextPanDelta(12, -4);
      expect(delta.x).assertEqual(12);
      expect(delta.y).assertEqual(-4);
      delta = tracker.nextPanDelta(17, 3);
      expect(delta.x).assertEqual(5);
      expect(delta.y).assertEqual(7);
      tracker.resetScale();
      tracker.resetPan();
      expect(tracker.nextScaleFactor(0.8)).assertEqual(0.8);
      delta = tracker.nextPanDelta(2, 6);
      expect(delta.x).assertEqual(2);
      expect(delta.y).assertEqual(6);
    });

    it('reports the visible page rectangle through the shared viewport transform', 0, () => {
      const viewport: CanvasViewport = new CanvasViewport();
      viewport.setZoomRaw(2);
      viewport.setScroll(-100, 50);
      const visible = viewport.visibleCanvasRect(800, 600);
      expect(visible !== null).assertTrue();
      if (visible !== null) {
        expect(visible.left).assertEqual(50);
        expect(visible.top).assertEqual(-25);
        expect(visible.right).assertEqual(450);
        expect(visible.bottom).assertEqual(275);
      }
      expect(viewport.visibleCanvasRect(0, 600) === null).assertTrue();
      viewport.zoom = ORIGINAL_VIEWPORT_MAX_ZOOM + 0.01;
      expect(viewport.visibleCanvasRect(800, 600) === null).assertTrue();
    });
  });
}
