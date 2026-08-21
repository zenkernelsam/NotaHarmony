// Pure Convert-to-Text planning boundary derived from original 1.0.3 xsc/bt1.
//
// The original action is a single transaction with three ordered mutations:
// DELETE_ENTITIES (selected Ink), CREATE_BLOCK (a Text Block at the selection
// bounds relative to the page origin), and INSERT_STRING (the recognizer text).
// Harmony now has a dedicated atomic persistence/history path for the mixed
// operation, but still has no production OCR provider, Locale adapter, or UI
// entry.  This module remains the pure request/result gate and never mutates
// UI, storage, or selection by itself.
import { Point2D, Rect2D, TransformMatrix } from '../model/GeometryTypes';
import { OriginalHandwritingRecognitionResult } from './OriginalHandwritingRecognition';
import {
  inspectOriginalHandwritingConversionText, OriginalHandwritingConversionTextStatus,
} from './OriginalHandwritingConversionTextPolicy';

export const ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE: number = 8;
// Kept as a compatibility alias for callers that imported the old name. The
// actual gate is the encoder's UTF-8 byte budget, not UTF-16 code-unit length.
export const ORIGINAL_HANDWRITING_CONVERSION_MAX_TEXT_LENGTH: number = 1048576;

/** A visible, already-decoded Ink candidate on one resolved page. */
export interface OriginalHandwritingConversionStroke {
  id: string;
  pageId: string;
  bounds: Rect2D;
  visible: boolean;
}

/** The page frame returned by the page model (xsc.j's origin component). */
export interface OriginalHandwritingConversionPageFrame {
  pageId: string;
  origin: Point2D;
}

export enum OriginalHandwritingConversionRejectReason {
  EMPTY_SELECTION = 0,
  DUPLICATE_SELECTION = 1,
  AMBIGUOUS_STROKE_ID = 2,
  MISSING_STROKE = 3,
  MIXED_PAGES = 4,
  HIDDEN_STROKE = 5,
  INVALID_BOUNDS = 6,
  MISSING_PAGE_FRAME = 7,
  INVALID_PAGE_FRAME = 8,
  INVALID_GENERATION = 9,
  INVALID_FINGERPRINT = 10,
  STALE_PAGE = 11,
  STALE_GENERATION = 12,
  STALE_SOURCE = 13,
  EMPTY_RESULT = 14,
  RESULT_TOO_LARGE = 15,
  RESULT_INVALID_UNICODE = 16,
  RESULT_WHITESPACE_ONLY = 17,
}

export interface OriginalHandwritingConversionRequest {
  selectedStrokeIds: string[];
  pageStrokes: OriginalHandwritingConversionStroke[];
  pageFrame: OriginalHandwritingConversionPageFrame | null;
  pageGeneration: number;
  sourceFingerprint: string;
}

export interface OriginalHandwritingConversionPlan {
  pageId: string;
  sourceStrokeIds: string[];
  selectionBounds: Rect2D;
  pageOrigin: Point2D;
  textOrigin: Point2D;
  width: number;
  height: number;
  // bt1 passes no optional transform to u5j.f; the created Text Block uses
  // the identity matrix while its origin is page-relative.
  textTransform: TransformMatrix;
  pageGeneration: number;
  sourceFingerprint: string;
}

export interface OriginalHandwritingConversionPlanResult {
  plan: OriginalHandwritingConversionPlan | null;
  reason: OriginalHandwritingConversionRejectReason | null;
  strokeId: string | null;
}

export interface OriginalHandwritingConversionResultCheck {
  accepted: boolean;
  reason: OriginalHandwritingConversionRejectReason | null;
}

export interface OriginalHandwritingTextMutation {
  pageId: string;
  deleteStrokeIds: string[];
  createText: OriginalHandwritingCreatedText;
  // This is the order required by bt1's shared xq9 transaction.
  operationOrder: string[];
  pageGeneration: number;
  sourceFingerprint: string;
}

export interface OriginalHandwritingCreatedText {
  id: string;
  origin: Point2D;
  width: number;
  height: number;
  transform: TransformMatrix;
  richText: string;
}

/**
 * Mirrors xsc.v() and xsc.j().  Bounds are expected in the same page/world
 * space used by the resolved page frame.  The result is deliberately a plan;
 * no entity is hidden or removed here.  The caller should pass the ordered IDs
 * from `adaptOriginalHandwritingSelection`; this planner does not invent a
 * second identity ordering policy.
 */
export function planOriginalHandwritingConversion(
  request: OriginalHandwritingConversionRequest): OriginalHandwritingConversionPlanResult {
  if (request.selectedStrokeIds.length === 0) {
    return rejected(OriginalHandwritingConversionRejectReason.EMPTY_SELECTION, null);
  }
  if (!validGeneration(request.pageGeneration)) {
    return rejected(OriginalHandwritingConversionRejectReason.INVALID_GENERATION, null);
  }
  if (request.sourceFingerprint.length === 0) {
    return rejected(OriginalHandwritingConversionRejectReason.INVALID_FINGERPRINT, null);
  }
  const frame: OriginalHandwritingConversionPageFrame | null = request.pageFrame;
  if (frame === null) {
    return rejected(OriginalHandwritingConversionRejectReason.MISSING_PAGE_FRAME, null);
  }
  if (frame.pageId.length === 0 || !finitePoint(frame.origin)) {
    return rejected(OriginalHandwritingConversionRejectReason.INVALID_PAGE_FRAME, null);
  }

  const byId: Map<string, OriginalHandwritingConversionStroke> =
    new Map<string, OriginalHandwritingConversionStroke>();
  const ambiguous: Set<string> = new Set<string>();
  for (const stroke of request.pageStrokes) {
    if (stroke.id.length === 0) {
      continue;
    }
    if (byId.has(stroke.id)) {
      ambiguous.add(stroke.id);
    } else {
      byId.set(stroke.id, stroke);
    }
  }

  const seen: Set<string> = new Set<string>();
  const selected: OriginalHandwritingConversionStroke[] = [];
  for (const strokeId of request.selectedStrokeIds) {
    if (seen.has(strokeId)) {
      return rejected(OriginalHandwritingConversionRejectReason.DUPLICATE_SELECTION, strokeId);
    }
    seen.add(strokeId);
    if (ambiguous.has(strokeId)) {
      return rejected(OriginalHandwritingConversionRejectReason.AMBIGUOUS_STROKE_ID, strokeId);
    }
    const stroke: OriginalHandwritingConversionStroke | undefined = byId.get(strokeId);
    if (stroke === undefined) {
      return rejected(OriginalHandwritingConversionRejectReason.MISSING_STROKE, strokeId);
    }
    if (stroke.pageId !== frame.pageId) {
      return rejected(OriginalHandwritingConversionRejectReason.MIXED_PAGES, strokeId);
    }
    if (!stroke.visible) {
      return rejected(OriginalHandwritingConversionRejectReason.HIDDEN_STROKE, strokeId);
    }
    if (!validBounds(stroke.bounds)) {
      return rejected(OriginalHandwritingConversionRejectReason.INVALID_BOUNDS, strokeId);
    }
    selected.push(stroke);
  }

  // xsc operates on Java float fields.  Keep the same Float32 rounding at
  // arithmetic boundaries instead of letting a double-only calculation move
  // an exact threshold by one ulp on Harmony.
  let left: number = originalFloat(selected[0].bounds.left);
  let top: number = originalFloat(selected[0].bounds.top);
  let right: number = originalFloat(selected[0].bounds.right);
  let bottom: number = originalFloat(selected[0].bounds.bottom);
  for (let index: number = 1; index < selected.length; index++) {
    const bounds: Rect2D = selected[index].bounds;
    left = Math.min(left, originalFloat(bounds.left));
    top = Math.min(top, originalFloat(bounds.top));
    right = Math.max(right, originalFloat(bounds.right));
    bottom = Math.max(bottom, originalFloat(bounds.bottom));
  }

  let width: number = originalFloat(right - left);
  let height: number = originalFloat(bottom - top);
  if (width < ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE) {
    left = originalFloat(left - originalFloat(
      (ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE - width) / 2));
    width = ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE;
  }
  if (height < ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE) {
    top = originalFloat(top - originalFloat(
      (ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE - height) / 2));
    height = ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE;
  }

  const sourceIds: string[] = selected.map(
    (stroke: OriginalHandwritingConversionStroke): string => stroke.id);
  const plan: OriginalHandwritingConversionPlan = {
    pageId: frame.pageId,
    sourceStrokeIds: sourceIds,
    selectionBounds: {
      left: left, top: top, right: originalFloat(left + width), bottom: originalFloat(top + height),
    },
    pageOrigin: { x: originalFloat(frame.origin.x), y: originalFloat(frame.origin.y) },
    textOrigin: {
      x: originalFloat(left - frame.origin.x), y: originalFloat(top - frame.origin.y),
    },
    width: width,
    height: height,
    textTransform: identityTransform(),
    pageGeneration: request.pageGeneration,
    sourceFingerprint: request.sourceFingerprint,
  };
  return { plan: plan, reason: null, strokeId: null };
}

/**
 * A provider result may arrive after a page switch, selection change, or save.
 * The original action is only valid for the exact page/generation/source that
 * produced the recognizer request.
 */
export function checkOriginalHandwritingConversionResult(
  plan: OriginalHandwritingConversionPlan,
  result: OriginalHandwritingRecognitionResult | null,
  currentPageId: string,
  currentGeneration: number,
  currentSourceFingerprint: string): OriginalHandwritingConversionResultCheck {
  if (currentPageId !== plan.pageId) {
    return { accepted: false, reason: OriginalHandwritingConversionRejectReason.STALE_PAGE };
  }
  if (currentGeneration !== plan.pageGeneration) {
    return { accepted: false, reason: OriginalHandwritingConversionRejectReason.STALE_GENERATION };
  }
  if (currentSourceFingerprint !== plan.sourceFingerprint) {
    return { accepted: false, reason: OriginalHandwritingConversionRejectReason.STALE_SOURCE };
  }
  if (result === null || result.text.length === 0) {
    return { accepted: false, reason: OriginalHandwritingConversionRejectReason.EMPTY_RESULT };
  }
  const inspection = inspectOriginalHandwritingConversionText(result.text);
  if (inspection.status === OriginalHandwritingConversionTextStatus.WHITESPACE_ONLY) {
    return { accepted: false,
      reason: OriginalHandwritingConversionRejectReason.RESULT_WHITESPACE_ONLY };
  }
  if (inspection.status === OriginalHandwritingConversionTextStatus.INVALID_UNICODE) {
    return {
      accepted: false,
      reason: OriginalHandwritingConversionRejectReason.RESULT_INVALID_UNICODE,
    };
  }
  if (inspection.status === OriginalHandwritingConversionTextStatus.TOO_LARGE) {
    return { accepted: false, reason: OriginalHandwritingConversionRejectReason.RESULT_TOO_LARGE };
  }
  if (inspection.status !== OriginalHandwritingConversionTextStatus.VALID) {
    return { accepted: false, reason: OriginalHandwritingConversionRejectReason.EMPTY_RESULT };
  }
  return { accepted: true, reason: null };
}

/**
 * Materializes the logical three-step mutation only after the caller has
 * reserved a fresh Text identity.  It intentionally does not touch storage.
 */
export function materializeOriginalHandwritingTextMutation(
  plan: OriginalHandwritingConversionPlan, textId: string,
  result: OriginalHandwritingRecognitionResult | null, currentPageId: string,
  currentGeneration: number, currentSourceFingerprint: string): OriginalHandwritingTextMutation | null {
  const check: OriginalHandwritingConversionResultCheck = checkOriginalHandwritingConversionResult(
    plan, result, currentPageId, currentGeneration, currentSourceFingerprint);
  if (!check.accepted || result === null || textId.length === 0 ||
    plan.sourceStrokeIds.indexOf(textId) >= 0) {
    return null;
  }
  return {
    pageId: plan.pageId,
    deleteStrokeIds: plan.sourceStrokeIds.slice(),
    createText: {
      id: textId,
      origin: { x: plan.textOrigin.x, y: plan.textOrigin.y },
      width: plan.width,
      height: plan.height,
      transform: plan.textTransform.slice(),
      richText: result.text,
    },
    operationOrder: ['DELETE_ENTITIES', 'CREATE_BLOCK', 'INSERT_STRING'],
    pageGeneration: plan.pageGeneration,
    sourceFingerprint: plan.sourceFingerprint,
  };
}

function rejected(reason: OriginalHandwritingConversionRejectReason,
  strokeId: string | null): OriginalHandwritingConversionPlanResult {
  return { plan: null, reason: reason, strokeId: strokeId };
}

function validGeneration(value: number): boolean {
  return Number.isSafeInteger(value) && value >= 0;
}

function finitePoint(point: Point2D): boolean {
  return Number.isFinite(point.x) && Number.isFinite(point.y);
}

function validBounds(bounds: Rect2D): boolean {
  return Number.isFinite(bounds.left) && Number.isFinite(bounds.top) &&
    Number.isFinite(bounds.right) && Number.isFinite(bounds.bottom) &&
    bounds.left <= bounds.right && bounds.top <= bounds.bottom;
}

function originalFloat(value: number): number {
  return Math.fround(value);
}

function identityTransform(): TransformMatrix {
  return [1, 0, 0, 0, 1, 0, 0, 0, 1];
}
