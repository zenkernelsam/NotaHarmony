import { describe, expect, it } from '@ohos/hypium';
import {
  OriginalNoteBlockWrapSupport, OriginalNoteLayoutMode,
} from '../main/ets/core/model/OriginalNoteMetadataPolicy';
import {
  BinaryOpWriter, encodeOperationString,
} from '../main/ets/data/BinaryOpCodec';
import {
  NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES, NOTE_METADATA_FIELD_ALL,
  NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT, NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY,
  NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE, NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE,
  NOTE_METADATA_FIELD_LAYOUT_MODE, NoteMetadataMutationState,
  cloneNoteMetadataMutationState, decodeNoteMetadataMutation,
  emptyNoteMetadataMutationState, encodeNoteMetadataMutation,
  patchFromNoteMetadataState, sameNoteMetadataMutationState,
  validateNoteMetadataMutationState,
} from '../main/ets/data/NoteMetadataMutationCodec';

export default function noteMetadataMutationCodecTest() {
  describe('NoteMetadataMutationCodec', () => {
    it('round-trips all six touched registers including null false and zero', 0, () => {
      const before: NoteMetadataMutationState = allState(
        null, false, '', 1, OriginalNoteLayoutMode.PAGED,
        OriginalNoteBlockWrapSupport.WRAP_ENABLED);
      const after: NoteMetadataMutationState = allState(
        'en_US', true, 'Noto Sans', 18.5, OriginalNoteLayoutMode.PAGELESS,
        OriginalNoteBlockWrapSupport.LEGACY_WRAP_ENABLED);
      const decoded = decodeNoteMetadataMutation(encodeNoteMetadataMutation({
        fromRevision: 7, toRevision: 8, selectedPageId: 'page-2',
        fieldMask: NOTE_METADATA_FIELD_ALL, before: before, after: after,
      }));
      expect(decoded.fromRevision).assertEqual(7);
      expect(decoded.toRevision).assertEqual(8);
      expect(decoded.selectedPageId).assertEqual('page-2');
      expect(decoded.fieldMask).assertEqual(NOTE_METADATA_FIELD_ALL);
      expect(decoded.before.handwritingLanguage === null).assertTrue();
      expect(decoded.before.alignTextToLines).assertFalse();
      expect(decoded.before.defaultFontFamily).assertEqual('');
      expect(decoded.before.defaultFontSize).assertEqual(1);
      expect(decoded.before.layoutMode).assertEqual(OriginalNoteLayoutMode.PAGED);
      expect(decoded.before.blockWrapSupport).assertEqual(
        OriginalNoteBlockWrapSupport.WRAP_ENABLED);
      expect(decoded.after.handwritingLanguage).assertEqual('en_US');
      expect(decoded.after.alignTextToLines).assertTrue();
      expect(decoded.after.defaultFontFamily).assertEqual('Noto Sans');
      expect(decoded.after.defaultFontSize).assertEqual(18.5);
      expect(decoded.after.layoutMode).assertEqual(OriginalNoteLayoutMode.PAGELESS);
      expect(decoded.after.blockWrapSupport).assertEqual(
        OriginalNoteBlockWrapSupport.LEGACY_WRAP_ENABLED);
    });

    it('converts a history target into an original presence patch', 0, () => {
      const target: NoteMetadataMutationState = allState(
        null, false, '', 1, OriginalNoteLayoutMode.PAGED,
        OriginalNoteBlockWrapSupport.WRAP_ENABLED);
      const patch = patchFromNoteMetadataState(target, NOTE_METADATA_FIELD_ALL);
      expect(patch.hasHandwritingLanguage).assertTrue();
      expect(patch.handwritingLanguage === null).assertTrue();
      expect(patch.hasAlignTextToLines).assertTrue();
      expect(patch.alignTextToLines).assertFalse();
      expect(patch.hasDefaultFontFamily).assertTrue();
      expect(patch.defaultFontFamily).assertEqual('');
      expect(patch.hasDefaultFontSize).assertTrue();
      expect(patch.defaultFontSize).assertEqual(1);
      expect(patch.hasLayoutMode).assertTrue();
      expect(patch.layoutMode).assertEqual(OriginalNoteLayoutMode.PAGED);
      expect(patch.hasBlockWrapSupport).assertTrue();
      expect(patch.blockWrapSupport).assertEqual(
        OriginalNoteBlockWrapSupport.WRAP_ENABLED);
    });

    it('keeps untouched fields null and only emits the selected subset', 0, () => {
      const mask: number = NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE |
        NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE;
      const before: NoteMetadataMutationState = emptyNoteMetadataMutationState();
      before.handwritingLanguage = null;
      before.defaultFontSize = 12;
      const after: NoteMetadataMutationState = cloneNoteMetadataMutationState(before);
      after.handwritingLanguage = 'zh_CN';
      after.defaultFontSize = 16;
      const decoded = decodeNoteMetadataMutation(encodeNoteMetadataMutation({
        fromRevision: 3, toRevision: 4, selectedPageId: 'page-1',
        fieldMask: mask, before: before, after: after,
      }));
      const patch = patchFromNoteMetadataState(decoded.after, decoded.fieldMask);
      expect(patch.hasHandwritingLanguage).assertTrue();
      expect(patch.hasDefaultFontSize).assertTrue();
      expect(patch.hasAlignTextToLines).assertFalse();
      expect(patch.hasDefaultFontFamily).assertFalse();
      expect(patch.hasLayoutMode).assertFalse();
      expect(patch.hasBlockWrapSupport).assertFalse();
      expect(decoded.after.alignTextToLines === null).assertTrue();
      expect(decoded.after.defaultFontFamily === null).assertTrue();
      expect(decoded.after.layoutMode === null).assertTrue();
      expect(decoded.after.blockWrapSupport === null).assertTrue();
      expect(sameNoteMetadataMutationState(before, after, mask)).assertFalse();
      expect(sameNoteMetadataMutationState(after,
        cloneNoteMetadataMutationState(after), mask)).assertTrue();
    });

    it('rejects unchanged mutations and invalid revision or mask identities', 0, () => {
      const before: NoteMetadataMutationState = alignState(false);
      const after: NoteMetadataMutationState = alignState(true);
      expect(() => encodeNoteMetadataMutation({
        fromRevision: 1, toRevision: 2, selectedPageId: 'page-1',
        fieldMask: NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES,
        before: before, after: cloneNoteMetadataMutationState(before),
      })).assertThrow();
      expect(() => encodeNoteMetadataMutation({
        fromRevision: 1, toRevision: 3, selectedPageId: 'page-1',
        fieldMask: NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES, before: before, after: after,
      })).assertThrow();
      expect(() => encodeNoteMetadataMutation({
        fromRevision: 1, toRevision: 2, selectedPageId: '',
        fieldMask: NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES, before: before, after: after,
      })).assertThrow();
      expect(() => encodeNoteMetadataMutation({
        fromRevision: 1, toRevision: 2, selectedPageId: 'page-1',
        fieldMask: 0, before: before, after: after,
      })).assertThrow();
      expect(() => validateNoteMetadataMutationState(before, 64, 'invalid mask')).assertThrow();
    });

    it('rejects absent ordinary winners and invalid touched values', 0, () => {
      expect(() => patchFromNoteMetadataState(
        emptyNoteMetadataMutationState(), NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES)).assertThrow();
      const wrongUntouched: NoteMetadataMutationState = alignState(false);
      wrongUntouched.defaultFontFamily = 'Serif';
      expect(() => validateNoteMetadataMutationState(
        wrongUntouched, NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES, 'wrong untouched')).assertThrow();
      const badFamily: NoteMetadataMutationState = emptyNoteMetadataMutationState();
      badFamily.defaultFontFamily = 'x'.repeat(31);
      expect(() => validateNoteMetadataMutationState(
        badFamily, NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY, 'bad family')).assertThrow();
      const badSize: NoteMetadataMutationState = emptyNoteMetadataMutationState();
      badSize.defaultFontSize = Number.NaN;
      expect(() => validateNoteMetadataMutationState(
        badSize, NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE, 'bad size')).assertThrow();
      const badLayout: NoteMetadataMutationState = emptyNoteMetadataMutationState();
      badLayout.layoutMode = 2;
      expect(() => validateNoteMetadataMutationState(
        badLayout, NOTE_METADATA_FIELD_LAYOUT_MODE, 'bad layout')).assertThrow();
      const badWrap: NoteMetadataMutationState = emptyNoteMetadataMutationState();
      badWrap.blockWrapSupport = 3;
      expect(() => validateNoteMetadataMutationState(
        badWrap, NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT, 'bad wrap')).assertThrow();
    });

    it('accepts touched handwriting explicit null but rejects unsupported language', 0, () => {
      const explicitNull: NoteMetadataMutationState = emptyNoteMetadataMutationState();
      explicitNull.handwritingLanguage = null;
      validateNoteMetadataMutationState(
        explicitNull, NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE, 'explicit null');
      const patch = patchFromNoteMetadataState(
        explicitNull, NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE);
      expect(patch.hasHandwritingLanguage).assertTrue();
      expect(patch.handwritingLanguage === null).assertTrue();
      const invalid: NoteMetadataMutationState = emptyNoteMetadataMutationState();
      invalid.handwritingLanguage = 'zz_US';
      expect(() => validateNoteMetadataMutationState(
        invalid, NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE, 'invalid language')).assertThrow();
    });

    it('rejects history values that the local original writer cannot restore', 0, () => {
      const oversizedLanguage: NoteMetadataMutationState = emptyNoteMetadataMutationState();
      oversizedLanguage.handwritingLanguage = `en_${'x'.repeat(1024)}`;
      expect(() => validateNoteMetadataMutationState(
        oversizedLanguage, NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE,
        'oversized language')).assertThrow();
      const malformedFamily: NoteMetadataMutationState = emptyNoteMetadataMutationState();
      malformedFamily.defaultFontFamily = '\uD800';
      expect(() => validateNoteMetadataMutationState(
        malformedFamily, NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY,
        'malformed family')).assertThrow();
    });

    it('fails closed on malformed JSON shape types and trailing bytes', 0, () => {
      const valid: string = JSON.stringify(alignState(true));
      expect(() => decodeNoteMetadataMutation(rawMutation(
        '{', valid, NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES))).assertThrow();
      expect(() => decodeNoteMetadataMutation(rawMutation(
        '[]', valid, NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES))).assertThrow();
      expect(() => decodeNoteMetadataMutation(rawMutation(
        '{"alignTextToLines":false}', valid,
        NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES))).assertThrow();
      expect(() => decodeNoteMetadataMutation(rawMutation(
        '{"handwritingLanguage":null,"alignTextToLines":false,"defaultFontFamily":null,' +
          '"defaultFontSize":null,"layoutMode":null,"blockWrapSupport":null,"extra":1}',
        valid, NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES))).assertThrow();
      expect(() => decodeNoteMetadataMutation(rawMutation(
        '{"handwritingLanguage":null,"alignTextToLines":"false","defaultFontFamily":null,' +
          '"defaultFontSize":null,"layoutMode":null,"blockWrapSupport":null}',
        valid, NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES))).assertThrow();
      const encoded: Uint8Array = rawMutation(
        JSON.stringify(alignState(false)), valid, NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES);
      const trailing: Uint8Array = new Uint8Array(encoded.length + 1);
      trailing.set(encoded, 0);
      trailing[encoded.length] = 1;
      expect(() => decodeNoteMetadataMutation(trailing)).assertThrow();
    });
  });
}

function allState(handwritingLanguage: string | null, alignTextToLines: boolean,
  defaultFontFamily: string, defaultFontSize: number, layoutMode: number,
  blockWrapSupport: number): NoteMetadataMutationState {
  return {
    handwritingLanguage: handwritingLanguage,
    alignTextToLines: alignTextToLines,
    defaultFontFamily: defaultFontFamily,
    defaultFontSize: defaultFontSize,
    layoutMode: layoutMode,
    blockWrapSupport: blockWrapSupport,
  };
}

function alignState(value: boolean): NoteMetadataMutationState {
  const state: NoteMetadataMutationState = emptyNoteMetadataMutationState();
  state.alignTextToLines = value;
  return state;
}

function rawMutation(beforeJson: string, afterJson: string, fieldMask: number): Uint8Array {
  const magic: Uint8Array = new Uint8Array([0x4E, 0x4D, 0x44, 0x31]);
  const page: Uint8Array = encodeOperationString('page-1', 'raw metadata page');
  const before: Uint8Array = encodeOperationString(beforeJson, 'raw metadata before');
  const after: Uint8Array = encodeOperationString(afterJson, 'raw metadata after');
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(
    magic.length + 16 + 4 + page.length + 1 + 4 + before.length + 4 + after.length));
  writer.writeBytes(magic);
  writer.writeSafeInteger(1);
  writer.writeSafeInteger(2);
  writer.writeSizedBytes(page);
  writer.writeByte(fieldMask);
  writer.writeSizedBytes(before);
  writer.writeSizedBytes(after);
  return writer.finish();
}
