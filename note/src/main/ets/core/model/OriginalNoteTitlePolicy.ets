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

// 原版 mcn.g（1.4.2 o8b.f ← k59.l）：新笔记自动标题组装。
//   parts = [日期若 datePos=PREFIX, 时间若 timePos=PREFIX]
//         + [base 若非 blank]（o8b.f：defaultNoteTitle 非 null 时覆盖 fallback）
//         + [日期若 datePos=SUFFIX, 时间若 timePos=SUFFIX]，空格连接。
// 日期 = ofLocalizedDate(MEDIUM)，时间 = ofLocalizedTime(SHORT)，均随系统 locale
//（zq.d/e = tj：locale 变化重建 formatter；Harmony Intl 默认 locale 等价）。
// 位置取值为原版 hmi 序列化名："None"/"Prefix"/"Suffix"（o8b 解码缺省
// date=SUFFIX、time=NONE）。全部分量丢弃时 k59.l 落回 "..."。
export const NOTE_TITLE_POSITION_NONE: string = 'None';
export const NOTE_TITLE_POSITION_PREFIX: string = 'Prefix';
export const NOTE_TITLE_POSITION_SUFFIX: string = 'Suffix';
// 原版 k59.l：mcn.g 结果 blank（如自定义标题清空且两个 include 均为 None）→ "..."。
export const ORIGINAL_AUTO_TITLE_EMPTY_FALLBACK: string = '...';

export function formatOriginalAutoNoteTitle(defaultNoteTitle: string | null,
  fallbackTitle: string, includeDatePosition: string,
  includeTimePosition: string, timestampMillis: number): string {
  const instant: Date = new Date(timestampMillis);
  const dateText: string = new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' })
    .format(instant);
  const timeText: string = new Intl.DateTimeFormat(undefined, { timeStyle: 'short' })
    .format(instant);
  const parts: string[] = [];
  if (includeDatePosition === NOTE_TITLE_POSITION_PREFIX) {
    parts.push(dateText);
  }
  if (includeTimePosition === NOTE_TITLE_POSITION_PREFIX) {
    parts.push(timeText);
  }
  // 原版 o8b.f：j8b.z != null → str = 自定义标题；r0h.T0（isNullOrBlank）
  // → blank 丢弃不入列。/\S/ 与 Kotlin Char.isWhitespace 同域（均不含 FEFF）。
  const base: string = defaultNoteTitle !== null ? defaultNoteTitle : fallbackTitle;
  if (/\S/.test(base)) {
    parts.push(base);
  }
  if (includeDatePosition === NOTE_TITLE_POSITION_SUFFIX) {
    parts.push(dateText);
  }
  if (includeTimePosition === NOTE_TITLE_POSITION_SUFFIX) {
    parts.push(timeText);
  }
  return parts.join(' ');
}
