import { describe, expect, it } from '@ohos/hypium';
import {
  NoteBackgroundSettings, OriginalPaperFlair, PageBackground, PageOrientation, PaperSize,
  PaperTemplate, PdfLayoutBehavior,
} from '../main/ets/core/model/NoteTypes';
import {
  applyOriginalPaperSettings, originalDefaultNoteBackgroundSettings, sameNoteBackgroundSettings,
  originalPaperOrientation,
} from '../main/ets/core/model/PageBackgroundModel';
import {
  decodeNoteBackgroundMutation, encodeNoteBackgroundMutation,
} from '../main/ets/data/NoteBackgroundMutationCodec';
import { persistOriginalNoteBackground } from
  '../main/ets/data/OriginalNoteBackgroundPersistence';
import { encodeOriginalOperationEnvelope } from
  '../main/ets/data/OriginalOperationEnvelopeEncoder';
import { encodeOriginalSetMetadataPageBackground } from
  '../main/ets/data/OriginalSetMetadataPayloadEncoder';
import {
  decodeOriginalSetMetadataTable, ORIGINAL_SET_METADATA_PAYLOAD_TYPE,
} from '../main/ets/data/OriginalSetMetadataOperation';
import { readOriginalPayloadTable } from
  '../main/ets/data/OriginalSyncedOperationFlatBuffer';

export default function originalSetMetadataPayloadEncoderTest() {
  describe('OriginalSetMetadataPayloadEncoder', () => {
    it('round-trips every supported PageBackground field', 0, () => {
      expect(persistOriginalNoteBackground !== undefined).assertTrue();
      const background: PageBackground = fullBackground();
      const decoded = decodeOriginalSetMetadataTable(readOriginalPayloadTable(
        wrap(encodeOriginalSetMetadataPageBackground(background)),
        ORIGINAL_SET_METADATA_PAYLOAD_TYPE));
      expect(decoded.hasTitle).assertFalse();
      expect(decoded.hasPageBackground).assertTrue();
      expect(decoded.pageBackground === null).assertFalse();
      if (decoded.pageBackground !== null) {
        expect(decoded.pageBackground.background.paper?.flair).assertEqual(OriginalPaperFlair.GRID);
        expect(decoded.pageBackground.background.paper?.flairSpacingPt).assertEqual(36);
        expect(decoded.pageBackground.background.paper?.flairBleeds).assertTrue();
        expect(decoded.pageBackground.background.paper?.flairCentered).assertFalse();
        expect(decoded.pageBackground.background.paper?.colorR).assertEqual(248);
        expect(decoded.pageBackground.background.paper?.legacyPaperIndex).assertEqual(9);
        expect(decoded.pageBackground.background.rotationRadians).assertEqual(Math.PI / 2);
        expect(decoded.pageBackground.background.sourceWidthPt).assertEqual(612);
        expect(decoded.pageBackground.background.sourceHeightPt).assertEqual(792);
        expect(decoded.pageBackground.background.margins?.topPt).assertEqual(36);
        expect(decoded.pageBackground.background.margins?.bottomPt).assertEqual(37);
        expect(decoded.pageBackground.background.margins?.leftPt).assertEqual(38);
        expect(decoded.pageBackground.background.margins?.rightPt).assertEqual(39);
        const pdf = decoded.pageBackground.background.pdf;
        expect(pdf === null || pdf === undefined).assertFalse();
        if (pdf !== null && pdf !== undefined) {
          expect(pdf.metadata.assetHashBits[0]).assertEqual('1');
          expect(pdf.metadata.assetHashBits[7]).assertEqual('18446744073709551615');
          expect(pdf.metadata.fileName).assertEqual('模板-一.pdf');
          expect(pdf.metadata.mimeType).assertEqual('application/pdf');
          expect(pdf.metadata.fileSize).assertEqual(987654);
          expect(pdf.layoutBehavior).assertEqual(PdfLayoutBehavior.DOWNSCALING_AND_CROP_BOX);
          expect(pdf.totalPageCount).assertEqual(5);
          expect(pdf.pagesConsumed).assertEqual(2);
          expect(pdf.pageOffset).assertEqual(1);
          expect(pdf.cropBoxes.length).assertEqual(2);
          expect(pdf.cropBoxes[0].widthPt).assertEqual(612);
          expect(pdf.cropBoxes[1].heightPt).assertEqual(1008);
        }
      }
    });

    it('keeps SetPageBackground present for an explicit null reset', 0, () => {
      const decoded = decodeOriginalSetMetadataTable(readOriginalPayloadTable(
        wrap(encodeOriginalSetMetadataPageBackground(null)),
        ORIGINAL_SET_METADATA_PAYLOAD_TYPE));
      expect(decoded.hasPageBackground).assertTrue();
      expect(decoded.pageBackground === null).assertTrue();
    });

    it('mirrors original paper conversion and preserves PDF plus rotation', 0, () => {
      const current: NoteBackgroundSettings = {
        background: fullBackground(), registerBackground: fullBackground(),
        template: PaperTemplate.GRID, size: PaperSize.LETTER,
        orientation: PageOrientation.PORTRAIT, widthMm: 279.4, heightMm: 215.9,
      };
      const changed: NoteBackgroundSettings = applyOriginalPaperSettings(
        current, PaperSize.A4, PaperTemplate.LINES, PageOrientation.PORTRAIT);
      expect(changed.background.pdf?.metadata.fileName).assertEqual('模板-一.pdf');
      expect(changed.background.rotationRadians).assertEqual(Math.PI / 2);
      expect(changed.orientation).assertEqual(PageOrientation.PORTRAIT);
      expect(changed.widthMm > changed.heightMm).assertTrue();
      expect(changed.background.paper?.flair).assertEqual(OriginalPaperFlair.LINES);
      expect(changed.background.paper?.flairSpacingPt).assertEqual(36);
      expect(changed.background.paper?.flairBleeds).assertFalse();
      expect(changed.background.paper?.flairCentered).assertFalse();
      expect(changed.background.paper?.colorA).assertEqual(255);
      expect(changed.background.margins?.topPt).assertEqual(36);
      expect(changed.background.sourceWidthPt === null).assertFalse();
      expect(changed.background.sourceHeightPt === null).assertFalse();
      const decoded = decodeOriginalSetMetadataTable(readOriginalPayloadTable(
        wrap(encodeOriginalSetMetadataPageBackground(changed.registerBackground)),
        ORIGINAL_SET_METADATA_PAYLOAD_TYPE));
      expect(decoded.pageBackground === null).assertFalse();
      if (decoded.pageBackground !== null) {
        const roundTripped: NoteBackgroundSettings = {
          background: decoded.pageBackground.background,
          registerBackground: decoded.pageBackground.background,
          template: decoded.pageBackground.template,
          size: decoded.pageBackground.size,
          orientation: originalPaperOrientation(decoded.pageBackground.background),
          widthMm: decoded.pageBackground.widthMm,
          heightMm: decoded.pageBackground.heightMm,
        };
        expect(sameNoteBackgroundSettings(roundTripped, changed)).assertTrue();
      }
    });

    it('round-trips NBG1 durable history state', 0, () => {
      const before: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
      const after: NoteBackgroundSettings = applyOriginalPaperSettings(
        before, PaperSize.LEGAL, PaperTemplate.DOTS, PageOrientation.LANDSCAPE);
      const decoded = decodeNoteBackgroundMutation(encodeNoteBackgroundMutation({
        fromRevision: 8, toRevision: 9, selectedPageId: 'page-2',
        before: before, after: after,
      }));
      expect(decoded.fromRevision).assertEqual(8);
      expect(decoded.toRevision).assertEqual(9);
      expect(decoded.selectedPageId).assertEqual('page-2');
      expect(decoded.before.registerBackground === null).assertTrue();
      expect(decoded.after.registerBackground === null).assertFalse();
      expect(sameNoteBackgroundSettings(decoded.before, before)).assertTrue();
      expect(sameNoteBackgroundSettings(decoded.after, after)).assertTrue();
      expect(() => encodeNoteBackgroundMutation({
        fromRevision: 8, toRevision: 10, selectedPageId: 'page-2',
        before: before, after: after,
      })).assertThrow();
    });
  });
}

function fullBackground(): PageBackground {
  return {
    schemaVersion: 2,
    paper: {
      flair: OriginalPaperFlair.GRID, flairSpacingPt: 36,
      flairBleeds: true, flairCentered: false,
      colorR: 248, colorG: 249, colorB: 250, colorA: 255,
      legacyPaperIndex: 9,
    },
    pdf: {
      metadata: {
        assetHashBits: ['1', '2', '3', '4', '5', '6', '7', '18446744073709551615'],
        fileName: '模板-一.pdf', mimeType: 'application/pdf', fileSize: 987654,
      },
      layoutBehavior: PdfLayoutBehavior.DOWNSCALING_AND_CROP_BOX,
      totalPageCount: 5, pagesConsumed: 2, pageOffset: 1,
      cropBoxes: [
        { widthPt: 612, heightPt: 792 },
        { widthPt: 612, heightPt: 1008 },
      ],
      pageInAsset: 1,
    },
    rotationRadians: Math.PI / 2,
    sourceWidthPt: 612,
    sourceHeightPt: 792,
    margins: { topPt: 36, bottomPt: 37, leftPt: 38, rightPt: 39 },
  };
}

function wrap(payload: Uint8Array): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: 100, siteId: 7 }, clientTime: '1234', serverTime: null,
    audioTime: null, payloadType: ORIGINAL_SET_METADATA_PAYLOAD_TYPE,
  }, payload);
}
