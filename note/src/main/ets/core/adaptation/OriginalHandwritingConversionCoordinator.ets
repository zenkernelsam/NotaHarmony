// Production orchestration boundary for the original 1.0.3 Convert-to-Text
// action. This module deliberately owns no UI, selection state, history stack,
// or database. It only wires the already-tested pure adapters together and
// reports a structured outcome to the caller.
import { StrokeElementData } from '../model/StrokeTypes';
import {
  adaptOriginalHandwritingSelection, OriginalHandwritingSelectionAdaptation,
} from './OriginalHandwritingSelectionAdapter';
import {
  OriginalHandwritingRecognitionContext, OriginalHandwritingRecognitionProvider,
  OriginalHandwritingRecognitionResult, recognizeAvailableOriginalHandwritingText,
} from './OriginalHandwritingRecognition';
import {
  checkOriginalHandwritingConversionResult, OriginalHandwritingConversionPlan,
  OriginalHandwritingConversionPageFrame, OriginalHandwritingConversionPlanResult,
  OriginalHandwritingConversionRejectReason, OriginalHandwritingConversionRequest,
  OriginalHandwritingConversionStroke,
  planOriginalHandwritingConversion,
} from './OriginalHandwritingConversionPlanner';
import {
  OriginalHandwritingConversionPersistencePlan, OriginalHandwritingConversionPersistenceResult,
} from '../../data/StrokePersistence';
import { decodePersistedElement, encodePersistedElement } from '../../data/PersistedElementCodec';
import { decodeOperationId } from '../../data/OperationIdentity';
import { HistoryCoalesceTrack, HistoryEffect, HistoryMetadata } from '../model/OpTypes';

export interface OriginalHandwritingConversionCoordinatorRequest {
  noteId: string;
  pageId: string;
  selectedStrokeIds: string[];
  // This is the one immutable-at-entry page snapshot used by selection,
  // planner, recognizer and persistence. The coordinator clones it before any
  // await, so a caller cannot mutate the request underneath an OCR provider.
  pageStrokes: StrokeElementData[];
  pageFrame: OriginalHandwritingConversionPageFrame | null;
  pageGeneration: number;
  sourceFingerprint: string;
  history: HistoryMetadata;
}

export interface OriginalHandwritingConversionFreshnessSnapshot {
  pageId: string;
  pageGeneration: number;
  sourceFingerprint: string;
}

export interface OriginalHandwritingConversionFreshnessReader {
  readCurrent(): Promise<OriginalHandwritingConversionFreshnessSnapshot>;
}

export interface OriginalHandwritingConversionContextReader {
  read(): Promise<OriginalHandwritingRecognitionContext>;
}

export interface OriginalHandwritingConversionPersistenceGateway {
  commitOriginalHandwritingConversion(noteId: string, pageId: string,
    plan: OriginalHandwritingConversionPersistencePlan, history: HistoryMetadata):
    Promise<OriginalHandwritingConversionPersistenceResult>;
}

export enum OriginalHandwritingConversionCoordinatorOutcome {
  SUCCESS = 0,
  INVALID_REQUEST = 1,
  PLAN_REJECTED = 2,
  PROVIDER_UNAVAILABLE = 3,
  CONTEXT_FAILURE = 4,
  PROVIDER_FAILURE = 5,
  PROVIDER_NO_RESULT = 6,
  RESULT_REJECTED = 7,
  STALE_RESULT = 8,
  FRESHNESS_FAILURE = 9,
  PERSISTENCE_FAILURE = 10,
  SOURCE_IDENTITY_UNSUPPORTED = 11,
}

export interface OriginalHandwritingConversionCoordinatorResult {
  outcome: OriginalHandwritingConversionCoordinatorOutcome;
  plan: OriginalHandwritingConversionPlan | null;
  selection: OriginalHandwritingSelectionAdaptation | null;
  rejectReason: OriginalHandwritingConversionRejectReason | null;
  error: Object | null;
  persistence: OriginalHandwritingConversionPersistenceResult | null;
}

/**
 * Runs one conversion attempt. Every failure is returned rather than thrown;
 * consequently the caller can leave selection, UI history and page content
 * untouched until the SUCCESS branch is observed.
 */
export async function runOriginalHandwritingConversion(
  request: OriginalHandwritingConversionCoordinatorRequest,
  provider: OriginalHandwritingRecognitionProvider | null,
  contextReader: OriginalHandwritingConversionContextReader,
  freshnessReader: OriginalHandwritingConversionFreshnessReader,
  persistence: OriginalHandwritingConversionPersistenceGateway):
  Promise<OriginalHandwritingConversionCoordinatorResult> {
  const invalid: OriginalHandwritingConversionCoordinatorResult | null = invalidRequest(request);
  if (invalid !== null) {
    return invalid;
  }
  const noteId: string = request.noteId;

  let history: HistoryMetadata;
  if (!validConversionHistory(request.history)) {
    return failure(OriginalHandwritingConversionCoordinatorOutcome.INVALID_REQUEST,
      null, null, new Error('original handwriting conversion requires PUSH/NONE history'));
  }
  history = {
    actionId: request.history.actionId, effect: request.history.effect,
    coalesceTrack: request.history.coalesceTrack, actionTime: request.history.actionTime,
  };

  let snapshot: StrokeElementData[];
  try {
    snapshot = request.pageStrokes.map(cloneStrokeSnapshot);
  } catch (error) {
    return failure(OriginalHandwritingConversionCoordinatorOutcome.INVALID_REQUEST,
      null, null, error);
  }

  const selection: OriginalHandwritingSelectionAdaptation = adaptOriginalHandwritingSelection(
    request.selectedStrokeIds, snapshot);
  const metadata: OriginalHandwritingConversionRequest = {
    selectedStrokeIds: selection.acceptedStrokeIds.slice(),
    pageStrokes: conversionStrokes(selection.acceptedStrokeIds, snapshot, request.pageId),
    pageFrame: request.pageFrame,
    pageGeneration: request.pageGeneration,
    sourceFingerprint: request.sourceFingerprint,
  };
  const planned: OriginalHandwritingConversionPlanResult =
    planOriginalHandwritingConversion(metadata);
  if (planned.plan === null) {
    return {
      outcome: OriginalHandwritingConversionCoordinatorOutcome.PLAN_REJECTED,
      plan: null, selection: selection, rejectReason: planned.reason,
      error: null, persistence: null,
    };
  }
  const plan: OriginalHandwritingConversionPlan = planned.plan;

  // The selected-stroke adapter deliberately accepts imported IDs so it can
  // remain useful at the provider boundary. This production coordinator,
  // however, commits through the original type-25 DELETE_ENTITIES path, whose
  // entities must carry canonical operation identities. Reject that known
  // incompatibility before context/provider work instead of spending an OCR
  // request only to fail the persistence preflight afterward.
  if (!hasOriginalPersistenceSourceIds(plan.sourceStrokeIds)) {
    return {
      outcome: OriginalHandwritingConversionCoordinatorOutcome.SOURCE_IDENTITY_UNSUPPORTED,
      plan: plan, selection: selection, rejectReason: null, error: null, persistence: null,
    };
  }

  if (provider === null) {
    return {
      outcome: OriginalHandwritingConversionCoordinatorOutcome.PROVIDER_UNAVAILABLE,
      plan: plan, selection: selection, rejectReason: null, error: null, persistence: null,
    };
  }
  let providerAvailable: boolean;
  try {
    providerAvailable = provider.isAvailable();
  } catch (error) {
    return failure(OriginalHandwritingConversionCoordinatorOutcome.PROVIDER_FAILURE,
      plan, selection, error);
  }
  if (!providerAvailable) {
    return {
      outcome: OriginalHandwritingConversionCoordinatorOutcome.PROVIDER_UNAVAILABLE,
      plan: plan, selection: selection, rejectReason: null, error: null, persistence: null,
    };
  }

  let context: OriginalHandwritingRecognitionContext;
  try {
    context = await contextReader.read();
  } catch (error) {
    return failure(OriginalHandwritingConversionCoordinatorOutcome.CONTEXT_FAILURE,
      plan, selection, error);
  }

  let recognition: OriginalHandwritingRecognitionResult | null;
  try {
    recognition = await recognizeAvailableOriginalHandwritingText(
      provider, selection.strokes, context);
  } catch (error) {
    return failure(OriginalHandwritingConversionCoordinatorOutcome.PROVIDER_FAILURE,
      plan, selection, error);
  }
  if (recognition === null) {
    return {
      outcome: OriginalHandwritingConversionCoordinatorOutcome.PROVIDER_NO_RESULT,
      plan: plan, selection: selection, rejectReason: null, error: null, persistence: null,
    };
  }

  let current: OriginalHandwritingConversionFreshnessSnapshot;
  try {
    current = await freshnessReader.readCurrent();
  } catch (error) {
    return failure(OriginalHandwritingConversionCoordinatorOutcome.FRESHNESS_FAILURE,
      plan, selection, error);
  }
  const checked = checkOriginalHandwritingConversionResult(
    plan, recognition, current.pageId, current.pageGeneration, current.sourceFingerprint);
  if (!checked.accepted) {
    const stale: boolean = checked.reason === OriginalHandwritingConversionRejectReason.STALE_PAGE ||
      checked.reason === OriginalHandwritingConversionRejectReason.STALE_GENERATION ||
      checked.reason === OriginalHandwritingConversionRejectReason.STALE_SOURCE;
    return {
      outcome: stale ? OriginalHandwritingConversionCoordinatorOutcome.STALE_RESULT :
        OriginalHandwritingConversionCoordinatorOutcome.RESULT_REJECTED,
      plan: plan, selection: selection, rejectReason: checked.reason,
      error: null, persistence: null,
    };
  }

  const sourceById: Map<string, StrokeElementData> = new Map<string, StrokeElementData>();
  for (const stroke of snapshot) {
    sourceById.set(stroke.id, stroke);
  }
  const sourceStrokes: StrokeElementData[] = [];
  for (const id of plan.sourceStrokeIds) {
    const source: StrokeElementData | undefined = sourceById.get(id);
    if (source === undefined) {
      return failure(OriginalHandwritingConversionCoordinatorOutcome.INVALID_REQUEST,
        plan, selection, new Error('conversion source snapshot lost an accepted stroke'));
    }
    sourceStrokes.push(cloneStrokeSnapshot(source));
  }
  const persistencePlan: OriginalHandwritingConversionPersistencePlan = {
    sourceStrokes: sourceStrokes,
    origin: { x: plan.textOrigin.x, y: plan.textOrigin.y },
    width: plan.width,
    height: plan.height,
    richText: recognition.text,
  };
  try {
    const committed: OriginalHandwritingConversionPersistenceResult =
      await persistence.commitOriginalHandwritingConversion(
        noteId, plan.pageId, persistencePlan, history);
    return {
      outcome: OriginalHandwritingConversionCoordinatorOutcome.SUCCESS,
      plan: plan, selection: selection, rejectReason: null, error: null, persistence: committed,
    };
  } catch (error) {
    return failure(OriginalHandwritingConversionCoordinatorOutcome.PERSISTENCE_FAILURE,
      plan, selection, error);
  }
}

function invalidRequest(request: OriginalHandwritingConversionCoordinatorRequest):
  OriginalHandwritingConversionCoordinatorResult | null {
  if (request === null || request === undefined || request.noteId.length === 0 ||
    request.pageId.length === 0 || !Array.isArray(request.selectedStrokeIds) ||
    !Array.isArray(request.pageStrokes) || request.pageFrame === undefined ||
    (request.pageFrame !== null && request.pageFrame.pageId !== request.pageId) ||
    request.sourceFingerprint.length === 0 ||
    request.history === null || request.history === undefined) {
    return failure(OriginalHandwritingConversionCoordinatorOutcome.INVALID_REQUEST,
      null, null, new Error('original handwriting conversion request is invalid'));
  }
  return null;
}

function validConversionHistory(history: HistoryMetadata): boolean {
  return typeof history.actionId === 'string' && history.actionId.length > 0 &&
    history.actionId.length <= 512 && Number.isSafeInteger(history.actionTime) &&
    history.actionTime >= 0 && history.effect === HistoryEffect.PUSH &&
    history.coalesceTrack === HistoryCoalesceTrack.NONE;
}

function hasOriginalPersistenceSourceIds(ids: string[]): boolean {
  for (const id of ids) {
    if (decodeOperationId(id) === null) {
      return false;
    }
  }
  return true;
}

function conversionStrokes(ids: string[], snapshot: StrokeElementData[], pageId: string):
  OriginalHandwritingConversionStroke[] {
  const byId: Map<string, StrokeElementData> = new Map<string, StrokeElementData>();
  for (const stroke of snapshot) {
    if (!byId.has(stroke.id)) {
      byId.set(stroke.id, stroke);
    }
  }
  const result: OriginalHandwritingConversionStroke[] = [];
  for (const id of ids) {
    const stroke: StrokeElementData | undefined = byId.get(id);
    if (stroke !== undefined) {
      result.push({
        id: stroke.id, pageId: pageId,
        bounds: {
          left: stroke.bounds.left, top: stroke.bounds.top,
          right: stroke.bounds.right, bottom: stroke.bounds.bottom,
        }, visible: true,
      });
    }
  }
  return result;
}

function cloneStrokeSnapshot(stroke: StrokeElementData): StrokeElementData {
  const persisted = decodePersistedElement(
    encodePersistedElement({ kind: 'stroke', data: stroke }));
  if (persisted.kind !== 'stroke') {
    throw new Error('conversion source snapshot changed kind');
  }
  return persisted.data as StrokeElementData;
}

function failure(outcome: OriginalHandwritingConversionCoordinatorOutcome,
  plan: OriginalHandwritingConversionPlan | null,
  selection: OriginalHandwritingSelectionAdaptation | null,
  error: Object): OriginalHandwritingConversionCoordinatorResult {
  return {
    outcome: outcome, plan: plan, selection: selection,
    rejectReason: null, error: error, persistence: null,
  };
}
