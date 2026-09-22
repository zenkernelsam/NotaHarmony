// Original 1.0.3 snap-to-grid / alignment guides.
// Sources: q7j.a (candidate generation), fjd (guide-kind priorities),
// ljd/ijd/jjd/kjd (candidate types + thresholds), m91.o + xe8.R
// (per-axis winner selection), remote flag ac4.S=SNAP_TO_GRID defaulting true
// (core_remoteconfig__remote_config_defaults.xml androidSnapToGrid=true).
//
// Thresholds are screen points; comparisons happen in page units, so each
// threshold is converted by POINTS_TO_PAGE_UNITS / zoom (m91 divides the
// candidate's pt threshold by the current zoom at construction).
import { Point2D, Rect2D } from './GeometryTypes';
import { PaperTemplate } from './NoteTypes';
import { POINTS_TO_PAGE_UNITS } from './PageBackgroundModel';

// Original fjd.I priority values: higher wins; equal priority prefers the
// smallest absolute delta (xe8.R).
export enum OriginalSnapGuideKind {
  GRID_LINE = 1,
  OBJECT_EDGE = 1,
  GRID_INTERSECTION = 2,
  OBJECT_CORNER = 2,
  OBJECT_CENTER = 3,
}

// Original thresholds (pt): jjd points=6, OBJECT_CENTER lines=6,
// OBJECT_EDGE lines=8, GRID_LINE lines=12.
const POINT_THRESHOLD_PT: number = 6.0;
const CENTER_THRESHOLD_PT: number = 6.0;
const EDGE_THRESHOLD_PT: number = 8.0;
const GRID_LINE_THRESHOLD_PT: number = 12.0;

export interface OriginalSnapGuideSegment {
  x1: number;
  y1: number;
  x2: number;
  y2: number;
}

// ljd: jjd is a point candidate (tests both axes); ijd is a horizontal line
// at y (tests y only); kjd is a vertical line at x (tests x only).
// guide is the candidate's b() segment (null for grid lines and points).
export interface OriginalSnapCandidate {
  kind: OriginalSnapGuideKind;
  priority: number;      // fjd.I
  thresholdPt: number;   // ljd.a()
  axis: 'x' | 'y' | 'xy';
  px: number;            // point x / vertical line x
  py: number;            // point y / horizontal line y
  guide: OriginalSnapGuideSegment | null;  // ljd.b()
}

export interface OriginalSnapMovePlan {
  dx: number;   // extra x adjustment (page units)
  dy: number;   // extra y adjustment (page units)
  guides: OriginalSnapGuideSegment[];  // winning candidates' segments (m91.i)
}

function segment(x1: number, y1: number, x2: number, y2: number): OriginalSnapGuideSegment {
  return { x1: x1, y1: y1, x2: x2, y2: y2 };
}

// q7j element candidates for one non-selected element's bounds:
// 4 corner points (OBJECT_CORNER 6pt), center vertical+horizontal lines
// (OBJECT_CENTER 6pt, guides spanning the element), and 4 edge lines
// (OBJECT_EDGE 8pt, guides on the edges).
export function originalSnapCandidatesForElementBounds(bounds: Rect2D): OriginalSnapCandidate[] {
  const cx: number = (bounds.left + bounds.right) / 2;
  const cy: number = (bounds.top + bounds.bottom) / 2;
  const candidates: OriginalSnapCandidate[] = [];
  const corners: Point2D[] = [
    { x: bounds.left, y: bounds.top },
    { x: bounds.right, y: bounds.top },
    { x: bounds.left, y: bounds.bottom },
    { x: bounds.right, y: bounds.bottom },
  ];
  for (const corner of corners) {
    candidates.push({
      kind: OriginalSnapGuideKind.OBJECT_CORNER,
      priority: OriginalSnapGuideKind.OBJECT_CORNER,
      thresholdPt: POINT_THRESHOLD_PT, axis: 'xy',
      px: corner.x, py: corner.y, guide: null,
    });
  }
  candidates.push({
    kind: OriginalSnapGuideKind.OBJECT_CENTER,
    priority: OriginalSnapGuideKind.OBJECT_CENTER,
    thresholdPt: CENTER_THRESHOLD_PT, axis: 'x',
    px: cx, py: cy, guide: segment(cx, bounds.top, cx, bounds.bottom),
  });
  candidates.push({
    kind: OriginalSnapGuideKind.OBJECT_CENTER,
    priority: OriginalSnapGuideKind.OBJECT_CENTER,
    thresholdPt: CENTER_THRESHOLD_PT, axis: 'y',
    px: cx, py: cy, guide: segment(bounds.left, cy, bounds.right, cy),
  });
  candidates.push({
    kind: OriginalSnapGuideKind.OBJECT_EDGE,
    priority: OriginalSnapGuideKind.OBJECT_EDGE,
    thresholdPt: EDGE_THRESHOLD_PT, axis: 'y',
    px: cx, py: bounds.top, guide: segment(bounds.left, bounds.top, bounds.right, bounds.top),
  });
  candidates.push({
    kind: OriginalSnapGuideKind.OBJECT_EDGE,
    priority: OriginalSnapGuideKind.OBJECT_EDGE,
    thresholdPt: EDGE_THRESHOLD_PT, axis: 'y',
    px: cx, py: bounds.bottom, guide: segment(bounds.left, bounds.bottom, bounds.right, bounds.bottom),
  });
  candidates.push({
    kind: OriginalSnapGuideKind.OBJECT_EDGE,
    priority: OriginalSnapGuideKind.OBJECT_EDGE,
    thresholdPt: EDGE_THRESHOLD_PT, axis: 'x',
    px: bounds.left, py: cy, guide: segment(bounds.left, bounds.top, bounds.left, bounds.bottom),
  });
  candidates.push({
    kind: OriginalSnapGuideKind.OBJECT_EDGE,
    priority: OriginalSnapGuideKind.OBJECT_EDGE,
    thresholdPt: EDGE_THRESHOLD_PT, axis: 'x',
    px: bounds.right, py: cy, guide: segment(bounds.right, bounds.top, bounds.right, bounds.bottom),
  });
  return candidates;
}

interface OriginalGridPositions {
  horizontal: number[];
  vertical: number[];
}

// i8j.c(w, h, spacing, centered, bleeds, true) — same math as PaperRenderer's
// gridPositions so candidate lines land exactly on drawn grid lines.
function originalGridPositions(width: number, height: number, spacing: number,
  centered: boolean, bleeds: boolean): OriginalGridPositions {
  const horizontal: number[] = [];
  const vertical: number[] = [];
  if (!centered) {
    const countY: number = Math.ceil(height / spacing);
    const countX: number = Math.ceil(width / spacing);
    const xOffset: number = bleeds ? (width - (countX + 1) * spacing) * 0.5 : 0;
    for (let index: number = 1; index <= countY; index++) {
      horizontal.push(index * spacing);
    }
    for (let index: number = 0; index <= countX; index++) {
      vertical.push(index * spacing + xOffset);
    }
    return { horizontal: horizontal, vertical: vertical };
  }
  const half: number = spacing / 2;
  const countY: number = Math.floor((height - half) / spacing);
  const countX: number = Math.floor((width - half) / spacing);
  const xOffset: number = (width - countX * spacing) / 2;
  const yOffset: number = (height - countY * spacing) / 2;
  for (let index: number = 0; index <= countY; index++) {
    horizontal.push(index * spacing + yOffset);
  }
  for (let index: number = 0; index <= countX; index++) {
    vertical.push(index * spacing + xOffset);
  }
  return { horizontal: horizontal, vertical: vertical };
}

// q7j.a grid branch: only GRID and DOTS paper produce candidates
// (LINES → q3a empty). GRID → GRID_LINE line candidates (12pt);
// DOTS → GRID_INTERSECTION point candidates (6pt). Candidates are filtered
// to the visible bounds (cmbVar2).
export function originalSnapGridCandidates(template: PaperTemplate,
  spacingPt: number | null, paperWidth: number, paperHeight: number,
  centered: boolean, bleeds: boolean, visible: Rect2D): OriginalSnapCandidate[] {
  if (template !== PaperTemplate.GRID && template !== PaperTemplate.DOTS) {
    return [];
  }
  if (spacingPt === null || !Number.isFinite(spacingPt) ||
    paperWidth <= 0 || paperHeight <= 0) {
    return [];
  }
  const spacing: number = spacingPt * POINTS_TO_PAGE_UNITS;
  if (spacing <= 1) {
    return [];
  }
  const positions: OriginalGridPositions =
    originalGridPositions(paperWidth, paperHeight, spacing, centered, bleeds);
  const candidates: OriginalSnapCandidate[] = [];
  if (template === PaperTemplate.GRID) {
    for (const y of positions.horizontal) {
      if (y >= visible.top && y <= visible.bottom) {
        candidates.push({
          kind: OriginalSnapGuideKind.GRID_LINE,
          priority: OriginalSnapGuideKind.GRID_LINE,
          thresholdPt: GRID_LINE_THRESHOLD_PT, axis: 'y',
          px: 0, py: y, guide: null,
        });
      }
    }
    for (const x of positions.vertical) {
      if (x >= visible.left && x <= visible.right) {
        candidates.push({
          kind: OriginalSnapGuideKind.GRID_LINE,
          priority: OriginalSnapGuideKind.GRID_LINE,
          thresholdPt: GRID_LINE_THRESHOLD_PT, axis: 'x',
          px: x, py: 0, guide: null,
        });
      }
    }
    return candidates;
  }
  for (const y of positions.horizontal) {
    for (const x of positions.vertical) {
      if (x >= visible.left && x <= visible.right && y >= visible.top && y <= visible.bottom) {
        candidates.push({
          kind: OriginalSnapGuideKind.GRID_INTERSECTION,
          priority: OriginalSnapGuideKind.GRID_INTERSECTION,
          thresholdPt: POINT_THRESHOLD_PT, axis: 'xy',
          px: x, py: y, guide: null,
        });
      }
    }
  }
  return candidates;
}

// fi3.c + fi3.b: dragged bounds contribute 4 corner anchors + the center.
export function originalSnapMoveAnchors(bounds: Rect2D): Point2D[] {
  return [
    { x: bounds.left, y: bounds.top },
    { x: bounds.right, y: bounds.top },
    { x: bounds.left, y: bounds.bottom },
    { x: bounds.right, y: bounds.bottom },
    { x: (bounds.left + bounds.right) / 2, y: (bounds.top + bounds.bottom) / 2 },
  ];
}

interface AxisSnap {
  delta: number;
  priority: number;
  guide: OriginalSnapGuideSegment | null;
  has: boolean;
}

// xe8.R: higher priority wins; same priority keeps the smaller |delta|.
function considerAxis(best: AxisSnap, delta: number, priority: number,
  guide: OriginalSnapGuideSegment | null): void {
  const wins: boolean = !best.has || priority > best.priority ||
    (priority === best.priority && Math.abs(delta) < Math.abs(best.delta));
  if (wins) {
    best.delta = delta;
    best.priority = priority;
    best.guide = guide;
    best.has = true;
  }
}

// m91.o + xe8.R: every dragged anchor (already translated by the proposed
// delta) is tested against every candidate; each axis keeps the
// highest-priority then smallest-|delta| winner. Returns the extra
// adjustment to apply and the winning guide segments (m91.i: non-null b()).
export function planOriginalSnapMove(anchors: Point2D[], dx: number, dy: number,
  candidates: OriginalSnapCandidate[], zoom: number): OriginalSnapMovePlan {
  const bestX: AxisSnap = { delta: 0, priority: -1, guide: null, has: false };
  const bestY: AxisSnap = { delta: 0, priority: -1, guide: null, has: false };
  if (candidates.length > 0 && zoom > 0) {
    for (const candidate of candidates) {
      const threshold: number =
        candidate.thresholdPt * POINTS_TO_PAGE_UNITS / zoom;
      for (const anchor of anchors) {
        const ax: number = anchor.x + dx;
        const ay: number = anchor.y + dy;
        if (candidate.axis === 'x' || candidate.axis === 'xy') {
          const deltaX: number = candidate.px - ax;
          if (Math.abs(deltaX) <= threshold) {
            considerAxis(bestX, deltaX, candidate.priority, candidate.guide);
          }
        }
        if (candidate.axis === 'y' || candidate.axis === 'xy') {
          const deltaY: number = candidate.py - ay;
          if (Math.abs(deltaY) <= threshold) {
            considerAxis(bestY, deltaY, candidate.priority, candidate.guide);
          }
        }
      }
    }
  }
  const guides: OriginalSnapGuideSegment[] = [];
  if (bestX.has && bestX.guide !== null) {
    guides.push(bestX.guide);
  }
  if (bestY.has && bestY.guide !== null && bestY.guide !== bestX.guide) {
    guides.push(bestY.guide);
  }
  return {
    dx: bestX.has ? bestX.delta : 0,
    dy: bestY.has ? bestY.delta : 0,
    guides: guides,
  };
}
