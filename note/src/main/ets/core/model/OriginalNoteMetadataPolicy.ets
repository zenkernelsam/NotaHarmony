// Original 1.0.3 l2d/tv6/dz0 metadata validation and enum contract.
// Java Locale.getISOLanguages() includes both the modern and legacy Java aliases
// (he/iw, id/in and yi/ji); l2d compares the exact prefix before the first '_'.

export const ORIGINAL_DEFAULT_FONT_FAMILY_MAX_LENGTH: number = 30;

export enum OriginalNoteLayoutMode {
  PAGED = 0,
  PAGELESS = 1,
}

export enum OriginalNoteBlockWrapSupport {
  WRAP_ENABLED = 0,
  WRAP_DISABLED = 1,
  LEGACY_WRAP_ENABLED = 2,
}

const ORIGINAL_ISO_LANGUAGE_CODES: string =
  '|aa|ab|ae|af|ak|am|an|ar|as|av|ay|az|ba|be|bg|bh|bi|bm|bn|bo|br|bs|' +
  'ca|ce|ch|co|cr|cs|cu|cv|cy|da|de|dv|dz|ee|el|en|eo|es|et|eu|fa|ff|' +
  'fi|fj|fo|fr|fy|ga|gd|gl|gn|gu|gv|ha|he|hi|ho|hr|ht|hu|hy|hz|ia|id|' +
  'ie|ig|ii|ik|in|io|is|it|iu|iw|ja|ji|jv|ka|kg|ki|kj|kk|kl|km|kn|ko|' +
  'kr|ks|ku|kv|kw|ky|la|lb|lg|li|ln|lo|lt|lu|lv|mg|mh|mi|mk|ml|mn|mo|' +
  'mr|ms|mt|my|na|nb|nd|ne|ng|nl|nn|no|nr|nv|ny|oc|oj|om|or|os|pa|pi|' +
  'pl|ps|pt|qu|rm|rn|ro|ru|rw|sa|sc|sd|se|sg|si|sk|sl|sm|sn|so|sq|sr|' +
  'ss|st|su|sv|sw|ta|te|tg|th|ti|tk|tl|tn|to|tr|ts|tt|tw|ty|ug|uk|ur|' +
  'uz|ve|vi|vo|wa|wo|xh|yi|yo|za|zh|zu|';

export function isOriginalHandwritingLanguage(value: string | null): boolean {
  if (value === null) {
    return true;
  }
  const separator: number = value.indexOf('_');
  const prefix: string = separator < 0 ? value : value.slice(0, separator);
  return ORIGINAL_ISO_LANGUAGE_CODES.includes(`|${prefix}|`);
}

export function isOriginalDefaultFontFamily(value: string): boolean {
  return value.length <= ORIGINAL_DEFAULT_FONT_FAMILY_MAX_LENGTH;
}

export function isOriginalDefaultFontSize(value: number): boolean {
  return Number.isFinite(value) && value > 0;
}

export function isOriginalNoteLayoutMode(value: number): boolean {
  return value === OriginalNoteLayoutMode.PAGED || value === OriginalNoteLayoutMode.PAGELESS;
}

export function isOriginalNoteBlockWrapSupport(value: number): boolean {
  return value === OriginalNoteBlockWrapSupport.WRAP_ENABLED ||
    value === OriginalNoteBlockWrapSupport.WRAP_DISABLED ||
    value === OriginalNoteBlockWrapSupport.LEGACY_WRAP_ENABLED;
}
