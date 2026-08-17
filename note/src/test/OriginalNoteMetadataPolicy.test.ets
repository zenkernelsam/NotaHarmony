import { describe, expect, it } from '@ohos/hypium';
import {
  isOriginalDefaultFontFamily, isOriginalDefaultFontSize, isOriginalHandwritingLanguage,
  isOriginalNoteBlockWrapSupport, isOriginalNoteLayoutMode,
  OriginalNoteBlockWrapSupport, OriginalNoteLayoutMode,
} from '../main/ets/core/model/OriginalNoteMetadataPolicy';

export default function originalNoteMetadataPolicyTest() {
  describe('OriginalNoteMetadataPolicy', () => {
    it('matches the original exact ISO language prefix rule', 0, () => {
      expect(isOriginalHandwritingLanguage(null)).assertTrue();
      expect(isOriginalHandwritingLanguage('en')).assertTrue();
      expect(isOriginalHandwritingLanguage('en_US')).assertTrue();
      expect(isOriginalHandwritingLanguage('he_IL')).assertTrue();
      expect(isOriginalHandwritingLanguage('iw_IL')).assertTrue();
      expect(isOriginalHandwritingLanguage('zz_US')).assertFalse();
      expect(isOriginalHandwritingLanguage('EN_US')).assertFalse();
      expect(isOriginalHandwritingLanguage('en-US')).assertFalse();
      expect(isOriginalHandwritingLanguage('')).assertFalse();
    });

    it('uses Java UTF-16 length and finite positive Float32 semantics', 0, () => {
      expect(isOriginalDefaultFontFamily('x'.repeat(30))).assertTrue();
      expect(isOriginalDefaultFontFamily('x'.repeat(31))).assertFalse();
      expect(isOriginalDefaultFontFamily('😀'.repeat(15))).assertTrue();
      expect(isOriginalDefaultFontFamily('😀'.repeat(16))).assertFalse();
      expect(isOriginalDefaultFontSize(17)).assertTrue();
      expect(isOriginalDefaultFontSize(0)).assertFalse();
      expect(isOriginalDefaultFontSize(-1)).assertFalse();
      expect(isOriginalDefaultFontSize(Number.NaN)).assertFalse();
      expect(isOriginalDefaultFontSize(Number.POSITIVE_INFINITY)).assertFalse();
    });

    it('accepts only the original layout and wrapping enum values', 0, () => {
      expect(isOriginalNoteLayoutMode(OriginalNoteLayoutMode.PAGED)).assertTrue();
      expect(isOriginalNoteLayoutMode(OriginalNoteLayoutMode.PAGELESS)).assertTrue();
      expect(isOriginalNoteLayoutMode(2)).assertFalse();
      expect(isOriginalNoteBlockWrapSupport(
        OriginalNoteBlockWrapSupport.WRAP_ENABLED)).assertTrue();
      expect(isOriginalNoteBlockWrapSupport(
        OriginalNoteBlockWrapSupport.WRAP_DISABLED)).assertTrue();
      expect(isOriginalNoteBlockWrapSupport(
        OriginalNoteBlockWrapSupport.LEGACY_WRAP_ENABLED)).assertTrue();
      expect(isOriginalNoteBlockWrapSupport(3)).assertFalse();
    });
  });
}
