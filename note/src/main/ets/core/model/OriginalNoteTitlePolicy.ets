// Original 1.0.3 keeps the editor draft at 200 UTF-16 code units, while the
// SetMetadata validator accepts a null inner value or concrete titles up to 256
// UTF-16 code units.
export const ORIGINAL_NOTE_TITLE_EDIT_MAX_LENGTH: number = 200;
export const ORIGINAL_NOTE_TITLE_WIRE_MAX_LENGTH: number = 256;
export const ORIGINAL_NOTE_DEFAULT_TITLE: string = 'New Note';

export function truncateOriginalNoteTitleDraft(value: string): string {
  if (value.length <= ORIGINAL_NOTE_TITLE_EDIT_MAX_LENGTH) {
    return value;
  }
  let end: number = ORIGINAL_NOTE_TITLE_EDIT_MAX_LENGTH;
  // Java's original substring limit is expressed in UTF-16 code units.  Keep
  // that same 200-unit ceiling, but do not manufacture an unpaired surrogate
  // when the boundary lands between the two halves of one Unicode scalar.
  const before: number = value.charCodeAt(end - 1);
  const after: number = value.charCodeAt(end);
  if (before >= 0xD800 && before <= 0xDBFF && after >= 0xDC00 && after <= 0xDFFF) {
    end--;
  }
  return value.slice(0, end);
}

// The original commit path does not trim whitespace. Only the exactly empty
// draft falls back to feature_note__default_title.
export function commitOriginalNoteTitleDraft(value: string): string {
  const truncated: string = truncateOriginalNoteTitleDraft(value);
  return truncated.length === 0 ? ORIGINAL_NOTE_DEFAULT_TITLE : truncated;
}

export function isOriginalNoteTitleWireValue(value: string | null): boolean {
  return value === null || value.length >= 1 &&
    value.length <= ORIGINAL_NOTE_TITLE_WIRE_MAX_LENGTH;
}

export function validateOriginalNoteTitleWireValue(value: string | null): void {
  if (!isOriginalNoteTitleWireValue(value)) {
    throw new Error('original note title must be null or contain 1 to 256 UTF-16 code units');
  }
}

// Original SetString distinguishes a missing wrapper (no patch) from a present
// wrapper whose inner string is null. Harmony keeps note_meta.title non-null for
// existing UI/query contracts, so only the materialized projection becomes empty.
export function materializeOriginalNoteTitle(value: string | null): string {
  return value === null ? '' : value;
}
