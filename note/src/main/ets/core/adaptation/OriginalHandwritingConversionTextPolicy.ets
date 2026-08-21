import {
  inspectOriginalInsertStringValue, OriginalInsertStringValueInspection,
  OriginalInsertStringValueStatus,
} from '../../data/OriginalInsertTextPayloadEncoder';

export enum OriginalHandwritingConversionTextStatus {
  VALID = 0,
  EMPTY = 1,
  WHITESPACE_ONLY = 2,
  INVALID_UNICODE = 3,
  TOO_LARGE = 4,
}

export interface OriginalHandwritingConversionTextInspection {
  status: OriginalHandwritingConversionTextStatus;
  byteLength: number;
}

/**
 * Shared recognizer-result gate. The original tsc/lvd/cq state machine rejects
 * a wholly blank string without trimming accepted text; the actual Harmony
 * INSERT_STRING payload additionally requires strict round-trippable UTF-8 and
 * a 1 MiB byte budget.
 */
export function inspectOriginalHandwritingConversionText(value: string):
  OriginalHandwritingConversionTextInspection {
  if (value.length === 0) {
    return { status: OriginalHandwritingConversionTextStatus.EMPTY, byteLength: 0 };
  }
  // tsc/lvd evaluates the semantic all-whitespace state before any later
  // INSERT_STRING serialization boundary. Preserve that precedence even for a
  // very large valid whitespace string; otherwise the same original result
  // would be reported as TOO_LARGE merely because Harmony measured its wire
  // bytes first.
  if (isOriginalHandwritingWhitespaceOnly(value)) {
    const whitespaceEncoded: OriginalInsertStringValueInspection =
      inspectOriginalInsertStringValue(value);
    return {
      status: OriginalHandwritingConversionTextStatus.WHITESPACE_ONLY,
      byteLength: whitespaceEncoded.byteLength,
    };
  }
  const encoded: OriginalInsertStringValueInspection = inspectOriginalInsertStringValue(value);
  if (encoded.status === OriginalInsertStringValueStatus.EMPTY) {
    return { status: OriginalHandwritingConversionTextStatus.EMPTY, byteLength: 0 };
  }
  if (encoded.status === OriginalInsertStringValueStatus.INVALID_UNICODE) {
    return {
      status: OriginalHandwritingConversionTextStatus.INVALID_UNICODE,
      byteLength: encoded.byteLength,
    };
  }
  if (encoded.status === OriginalInsertStringValueStatus.TOO_LARGE) {
    return {
      status: OriginalHandwritingConversionTextStatus.TOO_LARGE,
      byteLength: encoded.byteLength,
    };
  }
  return { status: OriginalHandwritingConversionTextStatus.VALID, byteLength: encoded.byteLength };
}

function isOriginalHandwritingWhitespaceOnly(value: string): boolean {
  for (let index: number = 0; index < value.length; index++) {
    if (!isOriginalWhitespaceCodeUnit(value.charCodeAt(index))) {
      return false;
    }
  }
  return true;
}

// Mirrors lvd.E0/cq.f0: Character.isWhitespace(c) || Character.isSpaceChar(c).
function isOriginalWhitespaceCodeUnit(code: number): boolean {
  return code === 0x0009 || code === 0x000A || code === 0x000B || code === 0x000C ||
    code === 0x000D || code === 0x001C || code === 0x001D || code === 0x001E ||
    code === 0x001F || code === 0x0020 || code === 0x00A0 || code === 0x1680 ||
    (code >= 0x2000 && code <= 0x200A) || code === 0x2028 || code === 0x2029 ||
    code === 0x202F || code === 0x205F || code === 0x3000;
}
