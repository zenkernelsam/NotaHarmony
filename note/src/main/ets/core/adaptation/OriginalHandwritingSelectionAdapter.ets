// Convert the Harmony page selection into the stroke stream expected by the
// original jc5/pm8 handwriting recognizer boundary.
//
// This module is deliberately pure. It does not open a provider, mutate the
// selection, or attempt to decode an original center path. A caller that owns
// a visible page supplies the already-decoded StrokeElementData values; this
// adapter only validates, orders, transforms, and copies their center samples.
import { Point2D, TransformMatrix } from '../model/GeometryTypes';
import { StrokeElementData, StrokePathPoint } from '../model/StrokeTypes';
import {
  OriginalHandwritingRecognitionSample, OriginalHandwritingRecognitionStroke,
} from './OriginalHandwritingRecognition';
import { compareOperationIdentity, decodeOperationId, OperationIdentity } from '../../data/OperationIdentity';

const AFFINE_EPSILON: number = 0.000000001;

/** Why one requested selection member was not forwarded to the OCR provider. */
export enum OriginalHandwritingSelectionSkipReason {
  MISSING_STROKE = 0,
  AMBIGUOUS_STROKE_ID = 1,
  DUPLICATE_SELECTION = 2,
  UNFINISHED_STROKE = 3,
  PARTIAL_ERASER = 4,
  HIGHLIGHTER = 5,
  EMPTY_CENTER_PATH = 6,
  INVALID_TRANSFORM = 7,
  INVALID_SAMPLE = 8,
}

export interface OriginalHandwritingSelectionSkip {
  strokeId: string;
  reason: OriginalHandwritingSelectionSkipReason;
}

export interface OriginalHandwritingSelectionAdaptation {
  // The order of these entries is the order the future provider must use.
  strokes: OriginalHandwritingRecognitionStroke[];
  acceptedStrokeIds: string[];
  skipped: OriginalHandwritingSelectionSkip[];
}

interface SelectionCandidate {
  strokeId: string;
  stroke: StrokeElementData;
  identity: OperationIdentity | null;
  recognition: OriginalHandwritingRecognitionStroke;
}

interface CanonicalCandidate {
  candidate: SelectionCandidate;
  identity: OperationIdentity;
}

/**
 * Mirrors jc5.a()/pm8.a() at the Harmony data boundary.
 *
 * `selectedStrokeIds` is the caller's selection collection. For IDs that can
 * be decoded as the original `op:timestamp:site` identity, the original
 * unsigned timestamp/site ordering is applied. Imported IDs (for example the
 * `nb-*` IDs produced by NotabilitySessionParser) have no original clock; they
 * therefore retain their input slots instead of being rejected or guessed into
 * an artificial operation identity. The caller is expected to pass visible
 * strokes belonging to one already-resolved page, so page-frame lookup and
 * hidden/deleted entity filtering have happened before this pure adapter.
 */
export function adaptOriginalHandwritingSelection(selectedStrokeIds: string[],
  pageStrokes: StrokeElementData[]): OriginalHandwritingSelectionAdaptation {
  const strokesById: Map<string, StrokeElementData> = new Map<string, StrokeElementData>();
  const ambiguousIds: Set<string> = new Set<string>();
  for (const stroke of pageStrokes) {
    if (strokesById.has(stroke.id)) {
      ambiguousIds.add(stroke.id);
    } else {
      strokesById.set(stroke.id, stroke);
    }
  }

  const skipped: OriginalHandwritingSelectionSkip[] = [];
  const seenSelectionIds: Set<string> = new Set<string>();
  const candidates: SelectionCandidate[] = [];
  for (const strokeId of selectedStrokeIds) {
    if (seenSelectionIds.has(strokeId)) {
      skipped.push({ strokeId: strokeId, reason: OriginalHandwritingSelectionSkipReason.DUPLICATE_SELECTION });
      continue;
    }
    seenSelectionIds.add(strokeId);

    if (ambiguousIds.has(strokeId)) {
      skipped.push({ strokeId: strokeId, reason: OriginalHandwritingSelectionSkipReason.AMBIGUOUS_STROKE_ID });
      continue;
    }
    const stroke: StrokeElementData | undefined = strokesById.get(strokeId);
    if (stroke === undefined) {
      skipped.push({ strokeId: strokeId, reason: OriginalHandwritingSelectionSkipReason.MISSING_STROKE });
      continue;
    }
    const reason: OriginalHandwritingSelectionSkipReason | null = eligibilityReason(stroke);
    if (reason !== null) {
      skipped.push({ strokeId: strokeId, reason: reason });
      continue;
    }
    const recognition: OriginalHandwritingRecognitionStroke | null = recognitionStroke(stroke);
    if (recognition === null) {
      skipped.push({ strokeId: strokeId, reason: OriginalHandwritingSelectionSkipReason.INVALID_SAMPLE });
      continue;
    }
    candidates.push({
      strokeId: strokeId,
      stroke: stroke,
      identity: decodeOperationId(strokeId),
      recognition: recognition,
    });
  }

  const canonical: CanonicalCandidate[] = [];
  for (const candidate of candidates) {
    if (candidate.identity !== null) {
      canonical.push({ candidate: candidate, identity: candidate.identity });
    }
  }
  canonical.sort((left: CanonicalCandidate, right: CanonicalCandidate): number =>
    compareOperationIdentity(left.identity, right.identity));

  // Replace only canonical slots. This is a stable merge for mixed pages:
  // imported IDs keep their input positions while comparable original IDs get
  // the exact so5 ordering.
  const ordered: SelectionCandidate[] = [];
  let canonicalIndex: number = 0;
  for (const candidate of candidates) {
    if (candidate.identity === null) {
      ordered.push(candidate);
    } else {
      ordered.push(canonical[canonicalIndex].candidate);
      canonicalIndex++;
    }
  }

  const strokes: OriginalHandwritingRecognitionStroke[] = [];
  const acceptedStrokeIds: string[] = [];
  for (const candidate of ordered) {
    strokes.push(candidate.recognition);
    acceptedStrokeIds.push(candidate.strokeId);
  }
  return { strokes: strokes, acceptedStrokeIds: acceptedStrokeIds, skipped: skipped };
}

function eligibilityReason(stroke: StrokeElementData): OriginalHandwritingSelectionSkipReason | null {
  if (!stroke.isFinished) {
    return OriginalHandwritingSelectionSkipReason.UNFINISHED_STROKE;
  }
  if (stroke.renderSpec.isPartialEraser === true) {
    return OriginalHandwritingSelectionSkipReason.PARTIAL_ERASER;
  }
  // wqh.e(s06) is exactly tool != HIGHLIGHTER. Tape and Pencil remain valid.
  if (stroke.renderSpec.isHighlighter) {
    return OriginalHandwritingSelectionSkipReason.HIGHLIGHTER;
  }
  if (stroke.pathPoints.length === 0) {
    return OriginalHandwritingSelectionSkipReason.EMPTY_CENTER_PATH;
  }
  if (!validAffineTransform(stroke.transform)) {
    return OriginalHandwritingSelectionSkipReason.INVALID_TRANSFORM;
  }
  return null;
}

function recognitionStroke(stroke: StrokeElementData): OriginalHandwritingRecognitionStroke | null {
  const samples: OriginalHandwritingRecognitionSample[] = [];
  for (const pathPoint of stroke.pathPoints) {
    if (!validPathPoint(pathPoint)) {
      return null;
    }
    const position: Point2D = transformPoint(pathPoint.position, stroke.transform);
    if (!Number.isFinite(position.x) || !Number.isFinite(position.y)) {
      return null;
    }
    samples.push({ position: position, force: pathPoint.pressure });
  }
  return samples.length === 0 ? null : { samples: samples };
}

function validPathPoint(pathPoint: StrokePathPoint): boolean {
  return Number.isFinite(pathPoint.position.x) && Number.isFinite(pathPoint.position.y) &&
    Number.isFinite(pathPoint.pressure);
}

function validAffineTransform(matrix: TransformMatrix): boolean {
  if (matrix.length !== 9) {
    return false;
  }
  for (const value of matrix) {
    if (!Number.isFinite(value)) {
      return false;
    }
  }
  if (Math.abs(matrix[6]) > AFFINE_EPSILON || Math.abs(matrix[7]) > AFFINE_EPSILON ||
    Math.abs(matrix[8] - 1) > AFFINE_EPSILON) {
    return false;
  }
  const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
  return Number.isFinite(determinant) && Math.abs(determinant) > AFFINE_EPSILON;
}

function transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
    y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
  };
}
