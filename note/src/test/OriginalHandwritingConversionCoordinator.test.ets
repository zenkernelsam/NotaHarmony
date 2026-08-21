import { describe, expect, it } from '@ohos/hypium';
import { ElementType, TextBlockElement } from '../main/ets/core/model/ElementTypes';
import { HistoryCoalesceTrack, HistoryEffect, HistoryMetadata, Op, OpType } from
  '../main/ets/core/model/OpTypes';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import {
  OriginalHandwritingConversionContextReader, OriginalHandwritingConversionCoordinatorOutcome,
  OriginalHandwritingConversionCoordinatorRequest, OriginalHandwritingConversionFreshnessReader,
  OriginalHandwritingConversionFreshnessSnapshot,
  OriginalHandwritingConversionPersistenceGateway, runOriginalHandwritingConversion,
} from '../main/ets/core/adaptation/OriginalHandwritingConversionCoordinator';
import {
  OriginalHandwritingRecognitionContext, OriginalHandwritingRecognitionProvider,
  OriginalHandwritingRecognitionStroke,
} from '../main/ets/core/adaptation/OriginalHandwritingRecognition';
import { OriginalHandwritingConversionRejectReason } from
  '../main/ets/core/adaptation/OriginalHandwritingConversionPlanner';
import {
  OriginalHandwritingConversionPersistencePlan, OriginalHandwritingConversionPersistenceResult,
} from '../main/ets/data/StrokePersistence';
import { OriginalHandwritingConversionMutation } from
  '../main/ets/data/OriginalHandwritingConversionMutationCodec';

class CoordinatorProvider implements OriginalHandwritingRecognitionProvider {
  available: boolean = true;
  text: string | null = 'hello';
  throwAvailability: boolean = false;
  throwRecognition: boolean = false;
  calls: number = 0;
  lastLocaleCode: string = '';
  lastStrokes: OriginalHandwritingRecognitionStroke[] = [];
  requestToMutate: OriginalHandwritingConversionCoordinatorRequest | null = null;

  isAvailable(): boolean {
    if (this.throwAvailability) {
      throw new Error('availability failed');
    }
    return this.available;
  }

  async recognizeText(strokes: OriginalHandwritingRecognitionStroke[], localeCode: string):
    Promise<string | null> {
    if (this.throwRecognition) {
      throw new Error('recognition failed');
    }
    this.calls++;
    this.lastStrokes = strokes;
    this.lastLocaleCode = localeCode;
    if (this.requestToMutate !== null) {
      this.requestToMutate.noteId = 'mutated-note';
    }
    return this.text;
  }
}

class CoordinatorContextReader implements OriginalHandwritingConversionContextReader {
  fail: boolean = false;

  async read(): Promise<OriginalHandwritingRecognitionContext> {
    if (this.fail) {
      throw new Error('context failed');
    }
    return {
      noteLanguage: 'zh-Hant', globalLanguage: null,
      systemLocale: { language: 'en', script: '', country: '' },
    };
  }
}

class CoordinatorFreshnessReader implements OriginalHandwritingConversionFreshnessReader {
  fail: boolean = false;
  snapshot: OriginalHandwritingConversionFreshnessSnapshot = {
    pageId: 'page-1', pageGeneration: 7, sourceFingerprint: 'fingerprint-7',
  };

  async readCurrent(): Promise<OriginalHandwritingConversionFreshnessSnapshot> {
    if (this.fail) {
      throw new Error('freshness failed');
    }
    return this.snapshot;
  }
}

class CoordinatorPersistence implements OriginalHandwritingConversionPersistenceGateway {
  fail: boolean = false;
  calls: number = 0;
  noteId: string = '';
  pageId: string = '';
  plan: OriginalHandwritingConversionPersistencePlan | null = null;
  history: HistoryMetadata | null = null;

  async commitOriginalHandwritingConversion(noteId: string, pageId: string,
    plan: OriginalHandwritingConversionPersistencePlan, history: HistoryMetadata):
    Promise<OriginalHandwritingConversionPersistenceResult> {
    if (this.fail) {
      throw new Error('commit failed');
    }
    this.calls++;
    this.noteId = noteId;
    this.pageId = pageId;
    this.plan = plan;
    this.history = history;
    return persistenceResult(plan.richText);
  }
}

export default function originalHandwritingConversionCoordinatorTest() {
  describe('OriginalHandwritingConversionCoordinator', () => {
    it('keeps accepted IDs OCR order and exact request snapshots through commit', 0, async () => {
      const sourceA: StrokeElementData = stroke('op:2:1', 20, 0.2);
      const sourceB: StrokeElementData = stroke('op:1:1', 10, 0.8);
      const request: OriginalHandwritingConversionCoordinatorRequest = baseRequest(
        [sourceA.id, sourceB.id], [sourceA, sourceB]);
      const provider = new CoordinatorProvider();
      provider.text = '  你好  ';
      provider.requestToMutate = request;
      const persistence = new CoordinatorPersistence();
      const result = await runOriginalHandwritingConversion(
        request, provider, new CoordinatorContextReader(),
        new CoordinatorFreshnessReader(), persistence);

      expect(result.outcome).assertEqual(OriginalHandwritingConversionCoordinatorOutcome.SUCCESS);
      expect(result.selection?.acceptedStrokeIds.join('|')).assertEqual('op:1:1|op:2:1');
      expect(result.plan?.sourceStrokeIds.join('|')).assertEqual('op:1:1|op:2:1');
      expect(provider.lastLocaleCode).assertEqual('zh_TW');
      expect(provider.lastStrokes[0].samples[0].force).assertEqual(0.8);
      expect(persistence.plan?.sourceStrokes.map((value: StrokeElementData): string => value.id)
        .join('|')).assertEqual('op:1:1|op:2:1');
      expect(persistence.plan?.richText).assertEqual('  你好  ');
      expect(persistence.noteId).assertEqual('note-1');
      expect(persistence.history?.effect).assertEqual(HistoryEffect.PUSH);
      expect(persistence.history?.coalesceTrack).assertEqual(HistoryCoalesceTrack.NONE);

      sourceB.pathPoints[0].position.x = 999;
      request.history.actionId = 'mutated';
      expect(persistence.plan?.sourceStrokes[0].pathPoints[0].position.x).assertEqual(10);
      expect(persistence.history?.actionId).assertEqual('convert-7');
      expect(request.noteId).assertEqual('mutated-note');
    });

    it('rejects plan/provider/context/freshness failures before persistence', 0, async () => {
      const empty = await runOriginalHandwritingConversion(
        baseRequest(['missing'], []), new CoordinatorProvider(), new CoordinatorContextReader(),
        new CoordinatorFreshnessReader(), new CoordinatorPersistence());
      expect(empty.outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.PLAN_REJECTED);
      expect(empty.rejectReason).assertEqual(OriginalHandwritingConversionRejectReason.EMPTY_SELECTION);

      const noFrameRequest: OriginalHandwritingConversionCoordinatorRequest = baseRequest();
      noFrameRequest.pageFrame = null;
      const noFrame = await runOriginalHandwritingConversion(
        noFrameRequest, new CoordinatorProvider(), new CoordinatorContextReader(),
        new CoordinatorFreshnessReader(), new CoordinatorPersistence());
      expect(noFrame.outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.PLAN_REJECTED);
      expect(noFrame.rejectReason).assertEqual(
        OriginalHandwritingConversionRejectReason.MISSING_PAGE_FRAME);

      const unavailable = new CoordinatorProvider();
      unavailable.available = false;
      const unavailablePersistence = new CoordinatorPersistence();
      expect((await runOriginalHandwritingConversion(
        baseRequest(), unavailable, new CoordinatorContextReader(),
        new CoordinatorFreshnessReader(), unavailablePersistence)).outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.PROVIDER_UNAVAILABLE);
      expect(unavailablePersistence.calls).assertEqual(0);

      const badContext = new CoordinatorContextReader();
      badContext.fail = true;
      expect((await runOriginalHandwritingConversion(
        baseRequest(), new CoordinatorProvider(), badContext,
        new CoordinatorFreshnessReader(), new CoordinatorPersistence())).outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.CONTEXT_FAILURE);

      const badFreshness = new CoordinatorFreshnessReader();
      badFreshness.fail = true;
      expect((await runOriginalHandwritingConversion(
        baseRequest(), new CoordinatorProvider(), new CoordinatorContextReader(),
        badFreshness, new CoordinatorPersistence())).outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.FRESHNESS_FAILURE);
    });

    it('rejects imported stroke identities before invoking OCR or persistence', 0, async () => {
      const provider = new CoordinatorProvider();
      const persistence = new CoordinatorPersistence();
      const result = await runOriginalHandwritingConversion(
        baseRequest(['nb-imported'], [stroke('nb-imported', 10, 0.8)]), provider,
        new CoordinatorContextReader(), new CoordinatorFreshnessReader(), persistence);
      expect(result.outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.SOURCE_IDENTITY_UNSUPPORTED);
      expect(provider.calls).assertEqual(0);
      expect(persistence.calls).assertEqual(0);
    });

    it('separates provider exception no-result invalid-result and stale-result outcomes', 0, async () => {
      const throwing = new CoordinatorProvider();
      throwing.throwRecognition = true;
      expect((await runOriginalHandwritingConversion(
        baseRequest(), throwing, new CoordinatorContextReader(),
        new CoordinatorFreshnessReader(), new CoordinatorPersistence())).outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.PROVIDER_FAILURE);

      const noResult = new CoordinatorProvider();
      noResult.text = null;
      expect((await runOriginalHandwritingConversion(
        baseRequest(), noResult, new CoordinatorContextReader(),
        new CoordinatorFreshnessReader(), new CoordinatorPersistence())).outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.PROVIDER_NO_RESULT);

      const blank = new CoordinatorProvider();
      blank.text = ' \u3000\n';
      const blankResult = await runOriginalHandwritingConversion(
        baseRequest(), blank, new CoordinatorContextReader(),
        new CoordinatorFreshnessReader(), new CoordinatorPersistence());
      expect(blankResult.outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.RESULT_REJECTED);
      expect(blankResult.rejectReason).assertEqual(
        OriginalHandwritingConversionRejectReason.RESULT_WHITESPACE_ONLY);

      const stale = new CoordinatorFreshnessReader();
      stale.snapshot.pageGeneration = 8;
      const stalePersistence = new CoordinatorPersistence();
      const staleResult = await runOriginalHandwritingConversion(
        baseRequest(), new CoordinatorProvider(), new CoordinatorContextReader(),
        stale, stalePersistence);
      expect(staleResult.outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.STALE_RESULT);
      expect(staleResult.rejectReason).assertEqual(
        OriginalHandwritingConversionRejectReason.STALE_GENERATION);
      expect(stalePersistence.calls).assertEqual(0);
    });

    it('returns persistence failure without claiming a successful conversion', 0, async () => {
      const persistence = new CoordinatorPersistence();
      persistence.fail = true;
      const result = await runOriginalHandwritingConversion(
        baseRequest(), new CoordinatorProvider(), new CoordinatorContextReader(),
        new CoordinatorFreshnessReader(), persistence);
      expect(result.outcome).assertEqual(
        OriginalHandwritingConversionCoordinatorOutcome.PERSISTENCE_FAILURE);
      expect(result.persistence === null).assertTrue();
    });
  });
}

function baseRequest(selected: string[] = ['op:1:1'],
  strokes: StrokeElementData[] = [stroke('op:1:1', 10, 0.8)]):
  OriginalHandwritingConversionCoordinatorRequest {
  return {
    noteId: 'note-1', pageId: 'page-1', selectedStrokeIds: selected,
    pageStrokes: strokes, pageFrame: { pageId: 'page-1', origin: { x: 2, y: 3 } },
    pageGeneration: 7, sourceFingerprint: 'fingerprint-7',
    history: {
      actionId: 'convert-7', effect: HistoryEffect.PUSH,
      coalesceTrack: HistoryCoalesceTrack.NONE, actionTime: 7000,
    },
  };
}

function stroke(id: string, x: number, force: number): StrokeElementData {
  return {
    id: id,
    pathPoints: [
      { position: { x: x, y: 20 }, widthFactor: 1, pressure: force,
        altitudeAngleRadians: 1, azimuthUnitX: 1, azimuthUnitY: 0 },
      { position: { x: x + 5, y: 25 }, widthFactor: 1, pressure: force,
        altitudeAngleRadians: 1, azimuthUnitX: 1, azimuthUnitY: 0 },
    ],
    cubicSegments: [], splatPoints: [],
    renderSpec: {
      color: -16777216, brushWidth: 2, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false, isPencil: false,
    },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: x, top: 20, right: x + 5, bottom: 25 },
    maskPath: [], isFinished: true,
  };
}

function persistenceResult(textValue: string): OriginalHandwritingConversionPersistenceResult {
  const text: TextBlockElement = {
    id: 'op:3:1', type: ElementType.TEXT,
    transform: [1, 0, 8, 0, 1, 17, 0, 0, 1],
    bounds: { left: 8, top: 17, right: 108, bottom: 57 }, richText: textValue,
    textOrigin: { x: 0, y: 0 }, blockWidth: 100, blockHeight: 40,
    rotationRadians: 0, contentLeftInset: 5, contentTopInset: 3,
    fontSize: 17, fontColor: -16777216,
  };
  const mutation: OriginalHandwritingConversionMutation = {
    pageMutation: {
      pageId: 'page-1', fromRevision: 7, toRevision: 8,
      beforeElements: [], afterElements: [], beforeOrder: [], afterOrder: [],
    },
    sourceStrokeIds: ['op:1:1'], textId: text.id,
  };
  const operation: Op = {
    opId: 'op:4:1', noteId: 'note-1', opType: OpType.ORIGINAL_HANDWRITING_CONVERSION,
    payload: new Uint8Array([1]), clientTime: 1,
  };
  return { elements: [], elementOrder: [], text: text, mutation: mutation, operation: operation };
}
