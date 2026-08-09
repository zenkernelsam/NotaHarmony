import {
  OriginalPaperFlair, PageBackground, PageBackgroundMargins, PageInfo, PagePaperBackground,
  PaperTemplate,
} from './NoteTypes';

export const PAGE_BACKGROUND_SCHEMA_VERSION: number = 1;
export const POINTS_TO_MM: number = 25.4 / 72.0;
export const POINTS_TO_PAGE_UNITS: number = 96.0 / 72.0;

export function clonePageBackground(value: PageBackground | null | undefined): PageBackground | null {
  if (value === undefined || value === null) {
    return null;
  }
  return {
    schemaVersion: value.schemaVersion,
    paper: clonePaper(value.paper),
    rotationRadians: value.rotationRadians,
    sourceWidthPt: value.sourceWidthPt,
    sourceHeightPt: value.sourceHeightPt,
    margins: cloneMargins(value.margins),
  };
}

export function clonePageInfo(page: PageInfo): PageInfo {
  return {
    pageId: page.pageId,
    pageIndex: page.pageIndex,
    size: page.size,
    template: page.template,
    orientation: page.orientation,
    widthMm: page.widthMm,
    heightMm: page.heightMm,
    background: clonePageBackground(page.background),
  };
}

export function samePageBackground(left: PageBackground | null | undefined,
  right: PageBackground | null | undefined): boolean {
  return serializePageBackground(left) === serializePageBackground(right);
}

export function validatePageBackground(value: PageBackground | null | undefined): void {
  if (value === undefined || value === null) {
    return;
  }
  if (value.schemaVersion !== PAGE_BACKGROUND_SCHEMA_VERSION ||
    !isCardinalRotation(value.rotationRadians) || !isOptionalNonNegativeFinite(value.sourceWidthPt) ||
    !isOptionalNonNegativeFinite(value.sourceHeightPt) ||
    (value.sourceWidthPt === null) !== (value.sourceHeightPt === null)) {
    throw new Error('page background header is invalid');
  }
  validateMargins(value.margins, value.sourceWidthPt, value.sourceHeightPt);
  validatePaper(value.paper);
}

export function serializePageBackground(value: PageBackground | null | undefined): string | null {
  if (value === undefined || value === null) {
    return null;
  }
  validatePageBackground(value);
  return JSON.stringify(value);
}

export function parsePageBackground(encoded: string | null): PageBackground | null {
  if (encoded === null || encoded.length === 0) {
    return null;
  }
  try {
    const value: PageBackground = JSON.parse(encoded) as PageBackground;
    validatePageBackground(value);
    return clonePageBackground(value);
  } catch (_error) {
    throw new Error('stored page background is invalid');
  }
}

export function templateForOriginalPaper(paper: PagePaperBackground | null): PaperTemplate {
  if (paper === null) {
    return PaperTemplate.PLAIN;
  }
  if (paper.flair === OriginalPaperFlair.GRID) {
    return PaperTemplate.GRID;
  }
  if (paper.flair === OriginalPaperFlair.DOTS) {
    return PaperTemplate.DOTS;
  }
  return paper.flairSpacingPt === null ? PaperTemplate.PLAIN : PaperTemplate.LINES;
}

export function pageBackgroundCssColor(value: PageBackground | null | undefined,
  fallback: string): string {
  const paper: PagePaperBackground | null = value === undefined || value === null ? null : value.paper;
  if (paper === null || paper.colorR === null || paper.colorG === null || paper.colorB === null ||
    paper.colorA === null) {
    return fallback;
  }
  return `rgba(${paper.colorR},${paper.colorG},${paper.colorB},${paper.colorA / 255.0})`;
}

function clonePaper(value: PagePaperBackground | null): PagePaperBackground | null {
  if (value === null) {
    return null;
  }
  return {
    flair: value.flair, flairSpacingPt: value.flairSpacingPt, flairBleeds: value.flairBleeds,
    flairCentered: value.flairCentered, colorR: value.colorR, colorG: value.colorG,
    colorB: value.colorB, colorA: value.colorA, legacyPaperIndex: value.legacyPaperIndex,
  };
}

function cloneMargins(value: PageBackgroundMargins | null): PageBackgroundMargins | null {
  if (value === null) {
    return null;
  }
  return { topPt: value.topPt, bottomPt: value.bottomPt, leftPt: value.leftPt, rightPt: value.rightPt };
}

function validatePaper(value: PagePaperBackground | null): void {
  if (value === null) {
    return;
  }
  if (value.flair !== null && (value.flair < OriginalPaperFlair.LINES ||
    value.flair > OriginalPaperFlair.GRID || !Number.isSafeInteger(value.flair))) {
    throw new Error('page paper flair is invalid');
  }
  if (!isOptionalFinite(value.flairSpacingPt) || !isOptionalBoolean(value.flairBleeds) ||
    !isOptionalBoolean(value.flairCentered) || !isOptionalByte(value.legacyPaperIndex)) {
    throw new Error('page paper options are invalid');
  }
  const colorCount: number = (value.colorR === null ? 0 : 1) + (value.colorG === null ? 0 : 1) +
    (value.colorB === null ? 0 : 1) + (value.colorA === null ? 0 : 1);
  if (colorCount !== 0 && (colorCount !== 4 || !isOptionalByte(value.colorR) ||
    !isOptionalByte(value.colorG) || !isOptionalByte(value.colorB) || value.colorA !== 255)) {
    throw new Error('page paper color is invalid');
  }
}

function validateMargins(value: PageBackgroundMargins | null, width: number | null,
  height: number | null): void {
  if (value === null) {
    return;
  }
  if (!isNonNegativeFinite(value.topPt) || !isNonNegativeFinite(value.bottomPt) ||
    !isNonNegativeFinite(value.leftPt) || !isNonNegativeFinite(value.rightPt)) {
    throw new Error('page background margins are invalid');
  }
  if (width !== null && height !== null &&
    (value.leftPt + value.rightPt > width || value.topPt + value.bottomPt > height)) {
    throw new Error('page background margins exceed its source size');
  }
}

function isCardinalRotation(value: number): boolean {
  return Number.isFinite(value) && (near(value, 0) || near(value, Math.PI / 2) ||
    near(value, Math.PI) || near(value, Math.PI * 3 / 2));
}

function near(left: number, right: number): boolean {
  return Math.abs(left - right) < 0.0001;
}

function isOptionalFinite(value: number | null): boolean {
  return value === null || Number.isFinite(value);
}

function isOptionalNonNegativeFinite(value: number | null): boolean {
  return value === null || isNonNegativeFinite(value);
}

function isNonNegativeFinite(value: number): boolean {
  return Number.isFinite(value) && value >= 0;
}

function isOptionalBoolean(value: boolean | null): boolean {
  return value === null || typeof value === 'boolean';
}

function isOptionalByte(value: number | null): boolean {
  return value === null || (Number.isSafeInteger(value) && value >= 0 && value <= 255);
}
