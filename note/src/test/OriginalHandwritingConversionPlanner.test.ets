import { describe, expect, it } from '@ohos/hypium';
import { OriginalHandwritingRecognitionResult } from '../main/ets/core/adaptation/OriginalHandwritingRecognition';
import { OriginalHandwritingLanguageSource } from '../main/ets/core/model/OriginalHandwritingLanguagePolicy';
import {
  checkOriginalHandwritingConversionResult,
  materializeOriginalHandwritingTextMutation,
  OriginalHandwritingConversionRejectReason,
  OriginalHandwritingConversionRequest,
  OriginalHandwritingConversionStroke,
  planOriginalHandwritingConversion,
} from '../main/ets/core/adaptation/OriginalHandwritingConversionPlanner';

export default function originalHandwritingConversionPlannerTest() {
  describe('OriginalHandwritingConversionPlanner', () => {
    it('mirrors xsc.j bounds expansion and bt1 page-relative origin', 0, () => {
      const request: OriginalHandwritingConversionRequest = {
        selectedStrokeIds: ['ink-b', 'ink-a'],
        pageStrokes: [
          stroke('ink-a', 'page-1', { left: 10, top: 20, right: 12, bottom: 23 }),
          stroke('ink-b', 'page-1', { left: 11, top: 18, right: 16, bottom: 21 }),
        ],
        pageFrame: { pageId: 'page-1', origin: { x: 4, y: 8 } },
        pageGeneration: 7,
        sourceFingerprint: 'rev:12|ink-a|ink-b',
      };
      const result = planOriginalHandwritingConversion(request);

      expect(result.reason === null).assertTrue();
      expect(result.plan === null).assertFalse();
      expect(result.plan?.sourceStrokeIds.join('|')).assertEqual('ink-b|ink-a');
      // Union is 6x5; each axis is centered to the original minimum 8.
      expect(result.plan?.selectionBounds.left).assertEqual(9);
      expect(result.plan?.selectionBounds.top).assertEqual(16.5);
      expect(result.plan?.width).assertEqual(8);
      expect(result.plan?.height).assertEqual(8);
      expect(result.plan?.textOrigin.x).assertEqual(5);
      expect(result.plan?.textOrigin.y).assertEqual(8.5);
      expect(result.plan?.textTransform.join(',')).assertEqual('1,0,0,0,1,0,0,0,1');
    });

    it('rejects mixed pages, hidden strokes, duplicate IDs, and missing frame', 0, () => {
      const base: OriginalHandwritingConversionRequest = {
        selectedStrokeIds: ['a', 'b'],
        pageStrokes: [stroke('a', 'page-1', box(0, 0, 10, 10)),
          stroke('b', 'page-2', box(0, 0, 10, 10))],
        pageFrame: { pageId: 'page-1', origin: { x: 0, y: 0 } },
        pageGeneration: 1,
        sourceFingerprint: 'f',
      };
      expect(planOriginalHandwritingConversion(base).reason).assertEqual(
        OriginalHandwritingConversionRejectReason.MIXED_PAGES);

      const hidden: OriginalHandwritingConversionRequest = {
        selectedStrokeIds: ['a'], pageStrokes: [stroke('a', 'page-1', box(0, 0, 1, 1), false)],
        pageFrame: base.pageFrame, pageGeneration: 1, sourceFingerprint: 'f',
      };
      expect(planOriginalHandwritingConversion(hidden).reason).assertEqual(
        OriginalHandwritingConversionRejectReason.HIDDEN_STROKE);

      const duplicate: OriginalHandwritingConversionRequest = {
        selectedStrokeIds: ['a', 'a'], pageStrokes: [stroke('a', 'page-1', box(0, 0, 1, 1))],
        pageFrame: base.pageFrame, pageGeneration: 1, sourceFingerprint: 'f',
      };
      expect(planOriginalHandwritingConversion(duplicate).reason).assertEqual(
        OriginalHandwritingConversionRejectReason.DUPLICATE_SELECTION);

      const noFrame: OriginalHandwritingConversionRequest = {
        selectedStrokeIds: ['a'], pageStrokes: [stroke('a', 'page-1', box(0, 0, 1, 1))],
        pageFrame: null, pageGeneration: 1, sourceFingerprint: 'f',
      };
      expect(planOriginalHandwritingConversion(noFrame).reason).assertEqual(
        OriginalHandwritingConversionRejectReason.MISSING_PAGE_FRAME);
    });

    it('rejects malformed source metadata before computing a mutation', 0, () => {
      const invalidBounds: OriginalHandwritingConversionRequest = {
        selectedStrokeIds: ['bad'], pageStrokes: [stroke('bad', 'page-1',
          { left: 3, top: 3, right: Number.NaN, bottom: 4 })],
        pageFrame: { pageId: 'page-1', origin: { x: 0, y: 0 } },
        pageGeneration: 1, sourceFingerprint: 'f',
      };
      expect(planOriginalHandwritingConversion(invalidBounds).reason).assertEqual(
        OriginalHandwritingConversionRejectReason.INVALID_BOUNDS);

      const invalidRequest: OriginalHandwritingConversionRequest = {
        selectedStrokeIds: ['a'], pageStrokes: [stroke('a', 'page-1', box(0, 0, 1, 1))],
        pageFrame: { pageId: 'page-1', origin: { x: 0, y: 0 } },
        pageGeneration: -1, sourceFingerprint: '',
      };
      expect(planOriginalHandwritingConversion(invalidRequest).reason).assertEqual(
        OriginalHandwritingConversionRejectReason.INVALID_GENERATION);
    });

    it('rejects stale blank invalid-Unicode and UTF-8-oversized OCR results', 0, () => {
      const plan = plan();
      const result: OriginalHandwritingRecognitionResult = recognition('hello');
      const stalePage = checkOriginalHandwritingConversionResult(
        plan, result, 'other-page', 3, 'fingerprint');
      expect(stalePage.accepted).assertFalse();
      expect(stalePage.reason).assertEqual(OriginalHandwritingConversionRejectReason.STALE_PAGE);
      const staleGeneration = checkOriginalHandwritingConversionResult(
        plan, result, 'page-1', 4, 'fingerprint');
      expect(staleGeneration.accepted).assertFalse();
      expect(staleGeneration.reason).assertEqual(
        OriginalHandwritingConversionRejectReason.STALE_GENERATION);
      const staleSource = checkOriginalHandwritingConversionResult(
        plan, result, 'page-1', 3, 'changed');
      expect(staleSource.accepted).assertFalse();
      expect(staleSource.reason).assertEqual(OriginalHandwritingConversionRejectReason.STALE_SOURCE);
      const empty = checkOriginalHandwritingConversionResult(
        plan, null, 'page-1', 3, 'fingerprint');
      expect(empty.accepted).assertFalse();
      expect(empty.reason).assertEqual(OriginalHandwritingConversionRejectReason.EMPTY_RESULT);

      const whitespace = checkOriginalHandwritingConversionResult(
        plan, recognition(' \u00A0\u3000\n'), 'page-1', 3, 'fingerprint');
      expect(whitespace.accepted).assertFalse();
      expect(whitespace.reason).assertEqual(
        OriginalHandwritingConversionRejectReason.RESULT_WHITESPACE_ONLY);

      // Semantic all-whitespace rejection follows the original tsc/lvd state
      // before the Harmony UTF-8 byte budget, even when the string is huge.
      const oversizedWhitespace = checkOriginalHandwritingConversionResult(
        plan, recognition(' '.repeat(1048577)), 'page-1', 3, 'fingerprint');
      expect(oversizedWhitespace.accepted).assertFalse();
      expect(oversizedWhitespace.reason).assertEqual(
        OriginalHandwritingConversionRejectReason.RESULT_WHITESPACE_ONLY);

      const exactAscii = checkOriginalHandwritingConversionResult(
        plan, recognition('x'.repeat(1048576)), 'page-1', 3, 'fingerprint');
      expect(exactAscii.accepted).assertTrue();
      const oversized = checkOriginalHandwritingConversionResult(
        plan, recognition('x'.repeat(1048577)), 'page-1', 3, 'fingerprint');
      expect(oversized.accepted).assertFalse();
      expect(oversized.reason).assertEqual(
        OriginalHandwritingConversionRejectReason.RESULT_TOO_LARGE);

      const multibyteOversized = checkOriginalHandwritingConversionResult(
        plan, recognition('中'.repeat(350000)), 'page-1', 3, 'fingerprint');
      expect(multibyteOversized.accepted).assertFalse();
      expect(multibyteOversized.reason).assertEqual(
        OriginalHandwritingConversionRejectReason.RESULT_TOO_LARGE);

      const loneSurrogate = checkOriginalHandwritingConversionResult(
        plan, recognition('\uD800'), 'page-1', 3, 'fingerprint');
      expect(loneSurrogate.accepted).assertFalse();
      expect(loneSurrogate.reason).assertEqual(
        OriginalHandwritingConversionRejectReason.RESULT_INVALID_UNICODE);
    });

    it('materializes the original delete/create/insert order without touching storage', 0, () => {
      const plan = plan();
      const mutation = materializeOriginalHandwritingTextMutation(
        plan, 'op:new:text', recognition('  hello  '), 'page-1', 3, 'fingerprint');
      expect(mutation === null).assertFalse();
      expect(mutation?.pageId).assertEqual('page-1');
      expect(mutation?.deleteStrokeIds.join('|')).assertEqual('ink-a|ink-b');
      expect(mutation?.operationOrder.join('|')).assertEqual(
        'DELETE_ENTITIES|CREATE_BLOCK|INSERT_STRING');
      expect(mutation?.createText.origin.x).assertEqual(8);
      expect(mutation?.createText.origin.y).assertEqual(8);
      expect(mutation?.createText.richText).assertEqual('  hello  ');
      expect(materializeOriginalHandwritingTextMutation(
        plan, 'ink-a', recognition('hello'), 'page-1', 3, 'fingerprint') === null).assertTrue();
    });
  });
}

function plan() {
  const request: OriginalHandwritingConversionRequest = {
    selectedStrokeIds: ['ink-a', 'ink-b'],
    pageStrokes: [stroke('ink-a', 'page-1', box(10, 10, 20, 20)),
      stroke('ink-b', 'page-1', box(20, 20, 30, 30))],
    pageFrame: { pageId: 'page-1', origin: { x: 2, y: 2 } },
    pageGeneration: 3,
    sourceFingerprint: 'fingerprint',
  };
  const result = planOriginalHandwritingConversion(request);
  if (result.plan === null) {
    throw new Error('fixture conversion plan unexpectedly rejected');
  }
  return result.plan;
}

function recognition(text: string): OriginalHandwritingRecognitionResult {
  return {
    text: text, localeCode: 'en_US', languageTag: 'en-US',
    languageSource: OriginalHandwritingLanguageSource.DEFAULT_ENGLISH,
  };
}

function stroke(id: string, pageId: string, bounds: { left: number; top: number; right: number; bottom: number },
  visible: boolean = true): OriginalHandwritingConversionStroke {
  return { id: id, pageId: pageId, bounds: bounds, visible: visible };
}

function box(left: number, top: number, right: number, bottom: number):
  { left: number; top: number; right: number; bottom: number } {
  return { left: left, top: top, right: right, bottom: bottom };
}
