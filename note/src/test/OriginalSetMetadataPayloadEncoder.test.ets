import { describe, expect, it } from '@ohos/hypium';
import {
  NoteBackgroundSettings, OriginalPaperFlair, PageBackground, PageOrientation, PaperSize,
  PaperTemplate, PdfLayoutBehavior,
} from '../main/ets/core/model/NoteTypes';
import {
  commitOriginalNoteTitleDraft, ORIGINAL_NOTE_DEFAULT_TITLE,
  truncateOriginalNoteTitleDraft,
} from '../main/ets/core/model/OriginalNoteTitlePolicy';
import {
  applyOriginalPaperSettings, originalDefaultNoteBackgroundSettings, sameNoteBackgroundSettings,
  originalPaperOrientation,
} from '../main/ets/core/model/PageBackgroundModel';
import {
  decodeNoteBackgroundMutation, encodeNoteBackgroundMutation,
} from '../main/ets/data/NoteBackgroundMutationCodec';
import {
  decodeNoteTitleMutation, encodeNoteTitleMutation,
} from '../main/ets/data/NoteTitleMutationCodec';
import {
  BinaryOpWriter, encodeOperationString,
} from '../main/ets/data/BinaryOpCodec';
import { persistOriginalNoteBackground } from
  '../main/ets/data/OriginalNoteBackgroundPersistence';
import { encodeOriginalOperationEnvelope } from
  '../main/ets/data/OriginalOperationEnvelopeEncoder';
import {
  encodeOriginalSetMetadataPageBackground, encodeOriginalSetMetadataTitle,
  encodeOriginalSetMetadataTitleAndPageBackground, encodeOriginalSetMetadataFields,
  OriginalNoteMetadataPatch,
} from
  '../main/ets/data/OriginalSetMetadataPayloadEncoder';
import {
  OriginalNoteBlockWrapSupport, OriginalNoteLayoutMode,
} from '../main/ets/core/model/OriginalNoteMetadataPolicy';
import {
  decodeOriginalSetMetadataTable, ORIGINAL_SET_METADATA_PAYLOAD_TYPE,
  OriginalSetMetadataOperationApplier,
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

    it('writes a title-only SetMetadata without resetting note background', 0, () => {
      const table = readOriginalPayloadTable(
        wrap(encodeOriginalSetMetadataTitle('标题 😀')),
        ORIGINAL_SET_METADATA_PAYLOAD_TYPE);
      const decoded = decodeOriginalSetMetadataTable(table);
      expect(decoded.hasTitle).assertTrue();
      expect(decoded.title).assertEqual('标题 😀');
      expect(decoded.hasPageBackground).assertFalse();
      expect(decoded.pageBackground === null).assertTrue();
      expect(new OriginalSetMetadataOperationApplier().preflightTable(table) === null).assertTrue();
      const clearTable = readOriginalPayloadTable(
        wrap(encodeOriginalSetMetadataTitle(null)), ORIGINAL_SET_METADATA_PAYLOAD_TYPE);
      const clear = decodeOriginalSetMetadataTable(clearTable);
      expect(clear.hasTitle).assertTrue();
      expect(clear.title === null).assertTrue();
      expect(new OriginalSetMetadataOperationApplier().preflightTable(clearTable) === null).assertTrue();
      expect(() => encodeOriginalSetMetadataTitle('')).assertThrow();
      expect(() => encodeOriginalSetMetadataTitle('x'.repeat(257))).assertThrow();
      expect(decodeOriginalSetMetadataTable(readOriginalPayloadTable(
        wrap(encodeOriginalSetMetadataTitle('x'.repeat(256))),
        ORIGINAL_SET_METADATA_PAYLOAD_TYPE)).title?.length).assertEqual(256);
    });

    it('writes the six local metadata registers with original presence semantics', 0, () => {
      const patch: OriginalNoteMetadataPatch = {
        hasHandwritingLanguage: true, handwritingLanguage: 'en_US',
        hasAlignTextToLines: true, alignTextToLines: true,
        hasDefaultFontFamily: true, defaultFontFamily: 'Noto Sans',
        hasDefaultFontSize: true, defaultFontSize: 18.5,
        hasLayoutMode: true, layoutMode: OriginalNoteLayoutMode.PAGELESS,
        hasBlockWrapSupport: true,
        blockWrapSupport: OriginalNoteBlockWrapSupport.LEGACY_WRAP_ENABLED,
      };
      const decoded = decodeOriginalSetMetadataTable(readOriginalPayloadTable(
        wrap(encodeOriginalSetMetadataFields(patch)), ORIGINAL_SET_METADATA_PAYLOAD_TYPE));
      expect(decoded.hasTitle).assertFalse();
      expect(decoded.hasPageBackground).assertFalse();
      expect(decoded.hasHandwritingLanguage).assertTrue();
      expect(decoded.handwritingLanguage).assertEqual('en_US');
      expect(decoded.hasAlignTextToLines && decoded.alignTextToLines).assertTrue();
      expect(decoded.defaultFontFamily).assertEqual('Noto Sans');
      expect(Math.abs(decoded.defaultFontSize - 18.5) < 0.0001).assertTrue();
      expect(decoded.layoutMode).assertEqual(OriginalNoteLayoutMode.PAGELESS);
      expect(decoded.blockWrapSupport).assertEqual(
        OriginalNoteBlockWrapSupport.LEGACY_WRAP_ENABLED);
    });

    it('keeps explicit-null handwriting and forced false/zero scalar fields present', 0, () => {
      const patch: OriginalNoteMetadataPatch = {
        hasHandwritingLanguage: true, handwritingLanguage: null,
        hasAlignTextToLines: true, alignTextToLines: false,
        hasDefaultFontFamily: true, defaultFontFamily: '',
        hasDefaultFontSize: true, defaultFontSize: 1,
        hasLayoutMode: true, layoutMode: OriginalNoteLayoutMode.PAGED,
        hasBlockWrapSupport: true,
        blockWrapSupport: OriginalNoteBlockWrapSupport.WRAP_ENABLED,
      };
      const decoded = decodeOriginalSetMetadataTable(readOriginalPayloadTable(
        wrap(encodeOriginalSetMetadataFields(patch)), ORIGINAL_SET_METADATA_PAYLOAD_TYPE));
      expect(decoded.hasHandwritingLanguage).assertTrue();
      expect(decoded.handwritingLanguage === null).assertTrue();
      expect(decoded.hasAlignTextToLines).assertTrue();
      expect(decoded.alignTextToLines).assertFalse();
      expect(decoded.hasDefaultFontFamily).assertTrue();
      expect(decoded.defaultFontFamily).assertEqual('');
      expect(decoded.hasDefaultFontSize).assertTrue();
      expect(decoded.hasLayoutMode).assertTrue();
      expect(decoded.layoutMode).assertEqual(OriginalNoteLayoutMode.PAGED);
      expect(decoded.hasBlockWrapSupport).assertTrue();
      expect(decoded.blockWrapSupport).assertEqual(
        OriginalNoteBlockWrapSupport.WRAP_ENABLED);
    });

    it('does not emit title/background or omitted preference fields', 0, () => {
      const patch: OriginalNoteMetadataPatch = {
        hasHandwritingLanguage: false, handwritingLanguage: null,
        hasAlignTextToLines: false, alignTextToLines: false,
        hasDefaultFontFamily: false, defaultFontFamily: '',
        hasDefaultFontSize: true, defaultFontSize: 12,
        hasLayoutMode: false, layoutMode: OriginalNoteLayoutMode.PAGED,
        hasBlockWrapSupport: false,
        blockWrapSupport: OriginalNoteBlockWrapSupport.WRAP_ENABLED,
      };
      const decoded = decodeOriginalSetMetadataTable(readOriginalPayloadTable(
        wrap(encodeOriginalSetMetadataFields(patch)), ORIGINAL_SET_METADATA_PAYLOAD_TYPE));
      expect(decoded.hasTitle).assertFalse();
      expect(decoded.hasPageBackground).assertFalse();
      expect(decoded.hasHandwritingLanguage).assertFalse();
      expect(decoded.hasAlignTextToLines).assertFalse();
      expect(decoded.hasDefaultFontFamily).assertFalse();
      expect(decoded.hasDefaultFontSize).assertTrue();
      expect(decoded.hasLayoutMode).assertFalse();
      expect(decoded.hasBlockWrapSupport).assertFalse();
    });

    it('rejects empty, invalid and unsupported local metadata patches', 0, () => {
      const empty: OriginalNoteMetadataPatch = {
        hasHandwritingLanguage: false, handwritingLanguage: null,
        hasAlignTextToLines: false, alignTextToLines: false,
        hasDefaultFontFamily: false, defaultFontFamily: '',
        hasDefaultFontSize: false, defaultFontSize: 1,
        hasLayoutMode: false, layoutMode: OriginalNoteLayoutMode.PAGED,
        hasBlockWrapSupport: false,
        blockWrapSupport: OriginalNoteBlockWrapSupport.WRAP_ENABLED,
      };
      expect(() => encodeOriginalSetMetadataFields(empty)).assertThrow();
      expect(() => encodeOriginalSetMetadataFields({
        ...empty, hasHandwritingLanguage: true, handwritingLanguage: 'zz_US',
      })).assertThrow();
      expect(() => encodeOriginalSetMetadataFields({
        ...empty, hasDefaultFontFamily: true, defaultFontFamily: 'x'.repeat(31),
      })).assertThrow();
      expect(() => encodeOriginalSetMetadataFields({
        ...empty, hasDefaultFontSize: true, defaultFontSize: 0,
      })).assertThrow();
      expect(() => encodeOriginalSetMetadataFields({
        ...empty, hasLayoutMode: true, layoutMode: 2 as OriginalNoteLayoutMode,
      })).assertThrow();
      expect(() => encodeOriginalSetMetadataFields({
        ...empty, hasBlockWrapSupport: true,
        blockWrapSupport: 3 as OriginalNoteBlockWrapSupport,
      })).assertThrow();
    });

    it('writes the combined title and concrete default background used by blank notes', 0, () => {
      const requested: NoteBackgroundSettings = applyOriginalPaperSettings(
        originalDefaultNoteBackgroundSettings(), PaperSize.LETTER,
        PaperTemplate.PLAIN, PageOrientation.PORTRAIT);
      const table = readOriginalPayloadTable(wrap(
        encodeOriginalSetMetadataTitleAndPageBackground(
          'New Note', requested.registerBackground as PageBackground)),
      ORIGINAL_SET_METADATA_PAYLOAD_TYPE);
      const decoded = decodeOriginalSetMetadataTable(table);
      expect(decoded.hasTitle).assertTrue();
      expect(decoded.title).assertEqual('New Note');
      expect(decoded.hasPageBackground).assertTrue();
      expect(decoded.pageBackground === null).assertFalse();
      expect(new OriginalSetMetadataOperationApplier().preflightTable(table) === null).assertTrue();
      if (decoded.pageBackground !== null) {
        expect(decoded.pageBackground.size).assertEqual(PaperSize.LETTER);
        expect(decoded.pageBackground.template).assertEqual(PaperTemplate.PLAIN);
        expect(decoded.pageBackground.background.margins?.topPt).assertEqual(36);
        expect(decoded.pageBackground.background.paper?.flairBleeds).assertTrue();
        expect(decoded.pageBackground.background.paper?.flairCentered).assertFalse();
      }
    });

    it('mirrors original title draft and empty-submit policy', 0, () => {
      expect(truncateOriginalNoteTitleDraft('x'.repeat(201)).length).assertEqual(200);
      expect(truncateOriginalNoteTitleDraft('x'.repeat(199) + '😀')).assertEqual('x'.repeat(199));
      expect(commitOriginalNoteTitleDraft('')).assertEqual(ORIGINAL_NOTE_DEFAULT_TITLE);
      expect(commitOriginalNoteTitleDraft('   ')).assertEqual('   ');
      expect(commitOriginalNoteTitleDraft('x'.repeat(201)).length).assertEqual(200);
    });

    it('round-trips NTL2 nullable title history and decodes legacy NTL1', 0, () => {
      const decoded = decodeNoteTitleMutation(encodeNoteTitleMutation({
        fromRevision: 4, toRevision: 5, selectedPageId: 'page-2',
        before: null, after: 'After',
      }));
      expect(decoded.fromRevision).assertEqual(4);
      expect(decoded.toRevision).assertEqual(5);
      expect(decoded.selectedPageId).assertEqual('page-2');
      expect(decoded.before === null).assertTrue();
      expect(decoded.after).assertEqual('After');
      const cleared = decodeNoteTitleMutation(encodeNoteTitleMutation({
        fromRevision: 5, toRevision: 6, selectedPageId: 'page-2',
        before: 'After', after: null,
      }));
      expect(cleared.before).assertEqual('After');
      expect(cleared.after === null).assertTrue();
      const legacy = decodeNoteTitleMutation(encodeLegacyNoteTitleMutation(
        8, 9, 'page-3', 'Before', 'After'));
      expect(legacy.before).assertEqual('Before');
      expect(legacy.after).assertEqual('After');
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

function encodeLegacyNoteTitleMutation(fromRevision: number, toRevision: number,
  selectedPageId: string, beforeValue: string, afterValue: string): Uint8Array {
  const magic: Uint8Array = new Uint8Array([0x4E, 0x54, 0x4C, 0x31]);
  const page: Uint8Array = encodeOperationString(selectedPageId, 'legacy title page ID');
  const before: Uint8Array = encodeOperationString(beforeValue, 'legacy title before');
  const after: Uint8Array = encodeOperationString(afterValue, 'legacy title after');
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(
    magic.length + 16 + 4 + page.length + 4 + before.length + 4 + after.length));
  writer.writeBytes(magic);
  writer.writeSafeInteger(fromRevision);
  writer.writeSafeInteger(toRevision);
  writer.writeSizedBytes(page);
  writer.writeSizedBytes(before);
  writer.writeSizedBytes(after);
  return writer.finish();
}
