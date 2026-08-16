import {
  PageOrientation, PaperSize, PaperTemplate,
} from './NoteTypes';

// Original 1.0.3 jq0 enum / Room string representation.
export enum OriginalPaperLineType {
  PLAIN = 'PLAIN',
  LINES = 'LINES',
  GRID = 'GRID',
  DOTS = 'DOTS',
}

export interface OriginalBackgroundInfo {
  paperLineType: OriginalPaperLineType;
  spacingInches: number | null;
  hasOptions: boolean;
}

// Original l3a/s3a/gq0 entity. id is deliberately excluded from semantic equality:
// Room assigns it on insert and the original app reuses the stored id only when deleting.
export interface OriginalPaperBackground {
  id: number;
  paperSize: PaperSize;
  paperOrientation: PageOrientation;
  backgroundColor: number | null;
  legacyPaperIndex: number | null;
  paperLineType: OriginalPaperLineType;
  spacingInches: number | null;
  hasOptions: boolean;
}

export interface OriginalRgbaColor {
  red: number;
  green: number;
  blue: number;
  alpha: number;
}

interface OriginalPackedPaperSize {
  size: PaperSize;
  value: string;
  approximateNumber: number;
}

export const ORIGINAL_PAPER_SPACING_INCHES: number[] = [
  Math.fround(0.1968505),
  Math.fround(0.25),
  Math.fround(0.393701),
  Math.fround(0.5),
  Math.fround(0.5905515),
  Math.fround(0.75),
  Math.fround(0.787402),
  Math.fround(1.0),
  Math.fround(1.181103),
  Math.fround(1.5),
];

const ORIGINAL_PAPER_LINE_TYPES: OriginalPaperLineType[] = [
  OriginalPaperLineType.PLAIN,
  OriginalPaperLineType.LINES,
  OriginalPaperLineType.GRID,
  OriginalPaperLineType.DOTS,
];

// ndj.f(h4a) packs metric width/height Float32 raw bits into one signed SQLite INTEGER.
// Keep decimal strings as the canonical ArkTS boundary: every value exceeds Number.MAX_SAFE_INTEGER.
const ORIGINAL_PACKED_PAPER_SIZES: OriginalPackedPaperSize[] = [
  packedPaperSize(PaperSize.A3, '4869657835720540160'),
  packedPaperSize(PaperSize.A4, '4850939749765251072'),
  packedPaperSize(PaperSize.A5, '4833488301204832256'),
  packedPaperSize(PaperSize.A6, '4814910952737865728'),
  packedPaperSize(PaperSize.A7, '4797459504177479680'),
  packedPaperSize(PaperSize.LETTER, '4852600450409280307'),
  packedPaperSize(PaperSize.LEGAL, '4852600450411777229'),
  packedPaperSize(PaperSize.TABLOID, '4867180855066879590'),
];

export function originalPaperLineTypes(): OriginalPaperLineType[] {
  return ORIGINAL_PAPER_LINE_TYPES.slice();
}

export function defaultOriginalBackgroundInfo(
  paperLineType: OriginalPaperLineType): OriginalBackgroundInfo {
  validateOriginalPaperLineType(paperLineType);
  if (paperLineType === OriginalPaperLineType.PLAIN) {
    return { paperLineType: paperLineType, spacingInches: null, hasOptions: false };
  }
  return {
    paperLineType: paperLineType,
    spacingInches: ORIGINAL_PAPER_SPACING_INCHES[3],
    hasOptions: true,
  };
}

export function validateOriginalBackgroundInfo(
  value: OriginalBackgroundInfo): OriginalBackgroundInfo {
  if (value === null || value === undefined) {
    throw new Error('original background info is invalid');
  }
  validateOriginalPaperLineType(value.paperLineType);
  if (typeof value.hasOptions !== 'boolean') {
    throw new Error('original background options flag is invalid');
  }
  if (value.paperLineType === OriginalPaperLineType.PLAIN) {
    if (value.spacingInches !== null || value.hasOptions) {
      throw new Error('original plain background info is invalid');
    }
    return { paperLineType: value.paperLineType, spacingInches: null, hasOptions: false };
  }
  return {
    paperLineType: value.paperLineType,
    spacingInches: value.spacingInches === null ? null :
      normalizeStoredOriginalPaperSpacingInches(value.spacingInches),
    hasOptions: value.hasOptions,
  };
}

export function normalizeOriginalPaperSpacingInches(value: number): number {
  if (!Number.isFinite(value)) {
    throw new Error('original paper spacing is invalid');
  }
  const normalized: number = Math.fround(value);
  for (const spacing of ORIGINAL_PAPER_SPACING_INCHES) {
    if (normalized === spacing) {
      return spacing;
    }
  }
  throw new Error('original paper spacing is not one of the original presets');
}

export function originalPaperSpacingPointsFromInches(value: number): number {
  const spacing: number = normalizeStoredOriginalPaperSpacingInches(value);
  return Math.fround(Math.fround(spacing) * Math.fround(72.0));
}

export function originalPaperSpacingInchesFromPoints(value: number): number {
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error('original paper point spacing is invalid');
  }
  return normalizeStoredOriginalPaperSpacingInches(
    Math.fround(Math.fround(value) / Math.fround(72.0)));
}

export function originalPaperLineTypeFromTemplate(template: PaperTemplate): OriginalPaperLineType {
  switch (template) {
    case PaperTemplate.PLAIN:
      return OriginalPaperLineType.PLAIN;
    case PaperTemplate.LINES:
      return OriginalPaperLineType.LINES;
    case PaperTemplate.GRID:
      return OriginalPaperLineType.GRID;
    case PaperTemplate.DOTS:
      return OriginalPaperLineType.DOTS;
    default:
      throw new Error('paper template is not an original picker line type');
  }
}

export function paperTemplateFromOriginalLineType(
  paperLineType: OriginalPaperLineType): PaperTemplate {
  validateOriginalPaperLineType(paperLineType);
  switch (paperLineType) {
    case OriginalPaperLineType.PLAIN:
      return PaperTemplate.PLAIN;
    case OriginalPaperLineType.LINES:
      return PaperTemplate.LINES;
    case OriginalPaperLineType.GRID:
      return PaperTemplate.GRID;
    case OriginalPaperLineType.DOTS:
      return PaperTemplate.DOTS;
  }
}

export function originalPackedPaperSize(size: PaperSize): string {
  validateOriginalPaperSize(size);
  for (const entry of ORIGINAL_PACKED_PAPER_SIZES) {
    if (entry.size === size) {
      return entry.value;
    }
  }
  throw new Error('original paper size mapping is missing');
}

export function originalPaperSizeFromPacked(value: string | number): PaperSize {
  if (typeof value === 'string') {
    if (!/^(0|[1-9][0-9]*)$/.test(value)) {
      throw new Error('stored original paper size is not a canonical integer');
    }
    for (const entry of ORIGINAL_PACKED_PAPER_SIZES) {
      if (entry.value === value) {
        return entry.size;
      }
    }
    throw new Error('stored original paper size is unsupported');
  }
  // Some ArkData paths expose SQLite INTEGER as a rounded JS number. Comparing the
  // value at that same boundary preserves recognition without ever writing it back.
  return originalPaperSizeFromApproximateNumber(value);
}

export function packOriginalArgb(red: number, green: number, blue: number,
  alpha: number = 255): number {
  validateColorByte(red, 'red');
  validateColorByte(green, 'green');
  validateColorByte(blue, 'blue');
  validateColorByte(alpha, 'alpha');
  return (alpha << 24) | (red << 16) | (green << 8) | blue;
}

export function unpackOriginalArgb(value: number): OriginalRgbaColor {
  validatePackedOriginalArgb(value);
  const unsigned: number = value >>> 0;
  return {
    red: (unsigned >>> 16) & 255,
    green: (unsigned >>> 8) & 255,
    blue: unsigned & 255,
    alpha: (unsigned >>> 24) & 255,
  };
}

export function validateOriginalPaperBackground(
  value: OriginalPaperBackground): OriginalPaperBackground {
  if (value === null || value === undefined) {
    throw new Error('original paper background is invalid');
  }
  validateOriginalPaperBackgroundId(value.id);
  validateOriginalPaperSize(value.paperSize);
  validateOriginalPaperOrientation(value.paperOrientation);
  validateOriginalPaperLineType(value.paperLineType);
  if (value.backgroundColor !== null) {
    validatePackedOriginalArgb(value.backgroundColor);
  }
  if (value.legacyPaperIndex !== null && (!Number.isSafeInteger(value.legacyPaperIndex) ||
    value.legacyPaperIndex < 0 || value.legacyPaperIndex > 255)) {
    throw new Error('original legacy paper index is invalid');
  }
  if (typeof value.hasOptions !== 'boolean') {
    throw new Error('original paper background options flag is invalid');
  }
  let spacingInches: number | null = null;
  if (value.paperLineType === OriginalPaperLineType.PLAIN) {
    if (value.spacingInches !== null || value.hasOptions) {
      throw new Error('original plain paper background is invalid');
    }
  } else {
    if (value.spacingInches !== null) {
      spacingInches = normalizeStoredOriginalPaperSpacingInches(value.spacingInches);
    }
  }
  return {
    id: value.id,
    paperSize: value.paperSize,
    paperOrientation: value.paperOrientation,
    backgroundColor: value.backgroundColor,
    legacyPaperIndex: value.legacyPaperIndex,
    paperLineType: value.paperLineType,
    spacingInches: spacingInches,
    hasOptions: value.hasOptions,
  };
}

export function sameOriginalPaperBackground(left: OriginalPaperBackground,
  right: OriginalPaperBackground): boolean {
  const normalizedLeft: OriginalPaperBackground = validateOriginalPaperBackground(left);
  const normalizedRight: OriginalPaperBackground = validateOriginalPaperBackground(right);
  return normalizedLeft.paperSize === normalizedRight.paperSize &&
    normalizedLeft.paperOrientation === normalizedRight.paperOrientation &&
    normalizedLeft.backgroundColor === normalizedRight.backgroundColor &&
    normalizedLeft.legacyPaperIndex === normalizedRight.legacyPaperIndex &&
    normalizedLeft.paperLineType === normalizedRight.paperLineType &&
    normalizedLeft.spacingInches === normalizedRight.spacingInches &&
    normalizedLeft.hasOptions === normalizedRight.hasOptions;
}

export function cloneOriginalPaperBackground(
  value: OriginalPaperBackground): OriginalPaperBackground {
  const normalized: OriginalPaperBackground = validateOriginalPaperBackground(value);
  return {
    id: normalized.id,
    paperSize: normalized.paperSize,
    paperOrientation: normalized.paperOrientation,
    backgroundColor: normalized.backgroundColor,
    legacyPaperIndex: normalized.legacyPaperIndex,
    paperLineType: normalized.paperLineType,
    spacingInches: normalized.spacingInches,
    hasOptions: normalized.hasOptions,
  };
}

function packedPaperSize(size: PaperSize, value: string): OriginalPackedPaperSize {
  return { size: size, value: value, approximateNumber: Number(value) };
}

function originalPaperSizeFromApproximateNumber(value: number): PaperSize {
  if (!Number.isFinite(value) || !Number.isInteger(value) || value <= 0) {
    throw new Error('stored original paper size is invalid');
  }
  for (const entry of ORIGINAL_PACKED_PAPER_SIZES) {
    if (entry.approximateNumber === value) {
      return entry.size;
    }
  }
  throw new Error('stored original paper size is unsupported');
}

function validateOriginalPaperBackgroundId(value: number): void {
  if (!Number.isSafeInteger(value) || value < 0 || value > 2147483647) {
    throw new Error('original paper background id is invalid');
  }
}

function validateOriginalPaperLineType(value: OriginalPaperLineType): void {
  if (value !== OriginalPaperLineType.PLAIN && value !== OriginalPaperLineType.LINES &&
    value !== OriginalPaperLineType.GRID && value !== OriginalPaperLineType.DOTS) {
    throw new Error('original paper line type is invalid');
  }
}

function validateOriginalPaperSize(value: PaperSize): void {
  if (!Number.isSafeInteger(value) || value < PaperSize.A3 || value > PaperSize.TABLOID) {
    throw new Error('original paper size is invalid');
  }
}

function validateOriginalPaperOrientation(value: PageOrientation): void {
  if (!Number.isSafeInteger(value) || value < PageOrientation.PORTRAIT ||
    value > PageOrientation.LANDSCAPE) {
    throw new Error('original paper orientation is invalid');
  }
}

function validateColorByte(value: number, component: string): void {
  if (!Number.isSafeInteger(value) || value < 0 || value > 255) {
    throw new Error(`original paper ${component} component is invalid`);
  }
}

function validatePackedOriginalArgb(value: number): void {
  if (!Number.isSafeInteger(value) || value < -2147483648 || value > 2147483647) {
    throw new Error('original packed paper color is invalid');
  }
}

function normalizeStoredOriginalPaperSpacingInches(value: number): number {
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error('stored original paper spacing is invalid');
  }
  const normalized: number = Math.fround(value);
  if (!Number.isFinite(normalized) || normalized <= 0) {
    throw new Error('stored original paper spacing is invalid');
  }
  return normalized;
}
