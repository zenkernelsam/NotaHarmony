import {
  NoteBackgroundSettings, OriginalAssetMetadata, OriginalPaperFlair, PageBackground, PageBackgroundMargins,
  PageInfo, PageOrientation, PagePaperBackground, PagePdfBackground, PaperSize, PaperTemplate,
  PdfCropBoxSize, PdfLayoutBehavior,
} from './NoteTypes';

export const PAGE_BACKGROUND_SCHEMA_VERSION: number = 2;
const LEGACY_PAGE_BACKGROUND_SCHEMA_VERSION: number = 1;
export const POINTS_TO_MM: number = 25.4 / 72.0;
export const POINTS_TO_PAGE_UNITS: number = 96.0 / 72.0;
const ORIGINAL_A_SERIES_MM_TO_POINTS: number = 2.83465;
const ORIGINAL_FLAIR_SPACING_PT: number = 36;
const ORIGINAL_MARGIN_PT: number = 36;

export function clonePageBackground(value: PageBackground | null | undefined): PageBackground | null {
  if (value === undefined || value === null) {
    return null;
  }
  return {
    schemaVersion: value.schemaVersion,
    paper: cloneOriginalPaper(value.paper),
    pdf: clonePdfBackground(value.pdf === undefined ? null : value.pdf),
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
    noteBackgroundFallback: clonePageBackground(page.noteBackgroundFallback),
    originalPageInAsset: page.originalPageInAsset,
  };
}

export function cloneNoteBackgroundSettings(value: NoteBackgroundSettings): NoteBackgroundSettings {
  return {
    background: clonePageBackground(value.background) as PageBackground,
    registerBackground: clonePageBackground(value.registerBackground),
    template: value.template,
    size: value.size,
    orientation: value.orientation,
    widthMm: value.widthMm,
    heightMm: value.heightMm,
  };
}

export function originalDefaultNoteBackgroundSettings(): NoteBackgroundSettings {
  return {
    background: originalDefaultNoteBackground(),
    registerBackground: null,
    template: PaperTemplate.PLAIN,
    size: PaperSize.LETTER,
    orientation: PageOrientation.PORTRAIT,
    widthMm: 215.9,
    heightMm: 279.4,
  };
}

export function noteBackgroundSettingsFromPage(page: PageInfo): NoteBackgroundSettings {
  const background: PageBackground | null = effectivePageBackground(page);
  if (background === null) {
    return applyOriginalPaperSettings(
      originalDefaultNoteBackgroundSettings(), page.size, page.template, page.orientation);
  }
  const result: NoteBackgroundSettings = {
    background: background,
    registerBackground: clonePageBackground(background),
    template: page.template,
    size: page.size,
    orientation: originalPaperOrientation(background),
    widthMm: page.widthMm,
    heightMm: page.heightMm,
  };
  validateNoteBackgroundSettings(result);
  return result;
}

// Mirrors l3a.a() from original 1.0.3. Paper edits replace paper/sourceSize/margins,
// preserve PDF + rotation, use a 0.5-inch flair interval, and reset all margins to 36 pt.
export function applyOriginalPaperSettings(current: NoteBackgroundSettings, size: PaperSize,
  template: PaperTemplate, orientation: PageOrientation): NoteBackgroundSettings {
  validateNoteBackgroundSettings(current);
  if (!Number.isSafeInteger(size) || size < PaperSize.A3 || size > PaperSize.TABLOID ||
    !Number.isSafeInteger(template) || template < PaperTemplate.PLAIN ||
    template > PaperTemplate.DOTS || !Number.isSafeInteger(orientation) ||
    orientation < PageOrientation.PORTRAIT || orientation > PageOrientation.LANDSCAPE) {
    throw new Error('original paper selection is invalid');
  }
  const portrait: number[] = originalPortraitSourcePoints(size);
  const sourceWidthPt: number = float32(orientation === PageOrientation.LANDSCAPE
    ? portrait[1] : portrait[0]);
  const sourceHeightPt: number = float32(orientation === PageOrientation.LANDSCAPE
    ? portrait[0] : portrait[1]);
  const background: PageBackground = clonePageBackground(current.background) as PageBackground;
  background.schemaVersion = PAGE_BACKGROUND_SCHEMA_VERSION;
  background.paper = originalPaperForTemplate(template);
  background.sourceWidthPt = sourceWidthPt;
  background.sourceHeightPt = sourceHeightPt;
  background.margins = {
    topPt: ORIGINAL_MARGIN_PT, bottomPt: ORIGINAL_MARGIN_PT,
    leftPt: ORIGINAL_MARGIN_PT, rightPt: ORIGINAL_MARGIN_PT,
  };
  const quarterTurn: boolean = near(background.rotationRadians, Math.PI / 2) ||
    near(background.rotationRadians, Math.PI * 3 / 2);
  const widthMm: number = (quarterTurn ? sourceHeightPt : sourceWidthPt) * POINTS_TO_MM;
  const heightMm: number = (quarterTurn ? sourceWidthPt : sourceHeightPt) * POINTS_TO_MM;
  const result: NoteBackgroundSettings = {
    background: background,
    registerBackground: clonePageBackground(background),
    template: template,
    size: size,
    orientation: orientation,
    widthMm: widthMm,
    heightMm: heightMm,
  };
  validateNoteBackgroundSettings(result);
  return result;
}

// Original fad.t() derives the paper picker orientation from nz9.sourceSize and deliberately
// ignores nz9.rotation. The rendered page dimensions below still include that rotation.
export function originalPaperOrientation(background: PageBackground): PageOrientation {
  if (background.sourceWidthPt === null || background.sourceHeightPt === null) {
    return PageOrientation.PORTRAIT;
  }
  return background.sourceWidthPt > background.sourceHeightPt
    ? PageOrientation.LANDSCAPE : PageOrientation.PORTRAIT;
}

export function sameNoteBackgroundSettings(left: NoteBackgroundSettings,
  right: NoteBackgroundSettings): boolean {
  return left.template === right.template && left.size === right.size &&
    left.orientation === right.orientation && left.widthMm === right.widthMm &&
    left.heightMm === right.heightMm && samePageBackground(left.background, right.background) &&
    samePageBackground(left.registerBackground, right.registerBackground);
}

export function validateNoteBackgroundSettings(value: NoteBackgroundSettings): void {
  if (!Number.isSafeInteger(value.template) || value.template < 0 ||
    value.template > PaperTemplate.DECORATIVE || !Number.isSafeInteger(value.size) ||
    value.size < 0 || value.size > 7 || !Number.isSafeInteger(value.orientation) ||
    value.orientation < 0 || value.orientation > 1 || !Number.isFinite(value.widthMm) ||
    !Number.isFinite(value.heightMm) || value.widthMm <= 0 || value.heightMm <= 0) {
    throw new Error('note background settings are invalid');
  }
  validatePageBackground(value.background);
  validatePageBackground(value.registerBackground);
  if (value.registerBackground === null) {
    const fallback: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
    if (value.template !== fallback.template || value.size !== fallback.size ||
      value.orientation !== fallback.orientation || value.widthMm !== fallback.widthMm ||
      value.heightMm !== fallback.heightMm ||
      !samePageBackground(value.background, fallback.background)) {
      throw new Error('null original note background register must use the original fallback');
    }
  } else if (!samePageBackground(value.background, value.registerBackground)) {
    throw new Error('concrete original note background register must match its effective value');
  }
}

function originalPortraitSourcePoints(size: PaperSize): number[] {
  switch (size) {
    case PaperSize.A3:
      return [297 * ORIGINAL_A_SERIES_MM_TO_POINTS, 420 * ORIGINAL_A_SERIES_MM_TO_POINTS];
    case PaperSize.A4:
      return [210 * ORIGINAL_A_SERIES_MM_TO_POINTS, 297 * ORIGINAL_A_SERIES_MM_TO_POINTS];
    case PaperSize.A5:
      return [148 * ORIGINAL_A_SERIES_MM_TO_POINTS, 210 * ORIGINAL_A_SERIES_MM_TO_POINTS];
    case PaperSize.A6:
      return [105 * ORIGINAL_A_SERIES_MM_TO_POINTS, 148 * ORIGINAL_A_SERIES_MM_TO_POINTS];
    case PaperSize.A7:
      return [74 * ORIGINAL_A_SERIES_MM_TO_POINTS, 105 * ORIGINAL_A_SERIES_MM_TO_POINTS];
    case PaperSize.LETTER:
      return [612, 792];
    case PaperSize.LEGAL:
      return [612, 1008];
    case PaperSize.TABLOID:
      return [792, 1224];
    default:
      throw new Error('original paper size is unsupported');
  }
}

function originalPaperForTemplate(template: PaperTemplate): PagePaperBackground {
  let flair: OriginalPaperFlair | null = null;
  if (template === PaperTemplate.LINES) {
    flair = OriginalPaperFlair.LINES;
  } else if (template === PaperTemplate.GRID) {
    flair = OriginalPaperFlair.GRID;
  } else if (template === PaperTemplate.DOTS) {
    flair = OriginalPaperFlair.DOTS;
  }
  return {
    flair: flair,
    flairSpacingPt: template === PaperTemplate.PLAIN ? null : ORIGINAL_FLAIR_SPACING_PT,
    flairBleeds: template !== PaperTemplate.LINES,
    flairCentered: false,
    colorR: 255, colorG: 255, colorB: 255, colorA: 255,
    legacyPaperIndex: null,
  };
}

function float32(value: number): number {
  const bytes: ArrayBuffer = new ArrayBuffer(4);
  const view: DataView = new DataView(bytes);
  view.setFloat32(0, value, true);
  return view.getFloat32(0, true);
}

export function effectivePageBackground(page: PageInfo): PageBackground | null {
  const result: PageBackground | null = page.background === undefined || page.background === null
    ? clonePageBackground(page.noteBackgroundFallback) : clonePageBackground(page.background);
  if (result !== null && result.pdf !== undefined && result.pdf !== null &&
    page.originalPageInAsset !== undefined) {
    result.pdf.pageInAsset = page.originalPageInAsset;
  }
  return result;
}

export function originalDefaultNoteBackground(): PageBackground {
  return {
    schemaVersion: PAGE_BACKGROUND_SCHEMA_VERSION,
    paper: {
      flair: null, flairSpacingPt: null, flairBleeds: null, flairCentered: null,
      colorR: 255, colorG: 255, colorB: 255, colorA: 255, legacyPaperIndex: null,
    },
    pdf: null,
    rotationRadians: 0,
    sourceWidthPt: 612,
    sourceHeightPt: 792,
    margins: null,
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
  if ((value.schemaVersion !== PAGE_BACKGROUND_SCHEMA_VERSION &&
    value.schemaVersion !== LEGACY_PAGE_BACKGROUND_SCHEMA_VERSION) ||
    !isCardinalRotation(value.rotationRadians) || !isOptionalNonNegativeFinite(value.sourceWidthPt) ||
    !isOptionalNonNegativeFinite(value.sourceHeightPt) ||
    (value.sourceWidthPt === null) !== (value.sourceHeightPt === null)) {
    throw new Error('page background header is invalid');
  }
  validateMargins(value.margins, value.sourceWidthPt, value.sourceHeightPt);
  validateOriginalPaper(value.paper);
  validatePdfBackground(value.pdf === undefined ? null : value.pdf, value.sourceWidthPt, value.sourceHeightPt,
    value.schemaVersion);
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

export function cloneOriginalPaper(value: PagePaperBackground | null): PagePaperBackground | null {
  if (value === null) {
    return null;
  }
  return {
    flair: value.flair, flairSpacingPt: value.flairSpacingPt, flairBleeds: value.flairBleeds,
    flairCentered: value.flairCentered, colorR: value.colorR, colorG: value.colorG,
    colorB: value.colorB, colorA: value.colorA, legacyPaperIndex: value.legacyPaperIndex,
  };
}

export function clonePdfBackground(value: PagePdfBackground | null): PagePdfBackground | null {
  if (value === null) {
    return null;
  }
  const cropBoxes: PdfCropBoxSize[] = [];
  for (const crop of value.cropBoxes) {
    cropBoxes.push({ widthPt: crop.widthPt, heightPt: crop.heightPt });
  }
  return {
    metadata: cloneAssetMetadata(value.metadata),
    layoutBehavior: value.layoutBehavior,
    totalPageCount: value.totalPageCount,
    pagesConsumed: value.pagesConsumed,
    pageOffset: value.pageOffset,
    cropBoxes: cropBoxes,
    pageInAsset: value.pageInAsset,
  };
}

function cloneAssetMetadata(value: OriginalAssetMetadata): OriginalAssetMetadata {
  return {
    assetHashBits: value.assetHashBits.slice(),
    fileName: value.fileName,
    mimeType: value.mimeType,
    fileSize: value.fileSize,
  };
}

function validatePdfBackground(value: PagePdfBackground | null, width: number | null,
  height: number | null, schemaVersion: number): void {
  if (value === null) {
    return;
  }
  if (schemaVersion !== PAGE_BACKGROUND_SCHEMA_VERSION || width === null || height === null ||
    !isUint32(value.totalPageCount) || value.totalPageCount === 0 ||
    !isUint32(value.pagesConsumed) || value.pagesConsumed === 0 ||
    !isUint32(value.pageOffset) || !isUint32(value.pageInAsset) ||
    value.pageOffset + value.pagesConsumed > value.totalPageCount ||
    value.pageInAsset < value.pageOffset || value.pageInAsset >= value.pageOffset + value.pagesConsumed ||
    value.cropBoxes.length !== value.pagesConsumed ||
    value.layoutBehavior < PdfLayoutBehavior.DOWNSCALING_AND_MAX_BOX ||
    value.layoutBehavior > PdfLayoutBehavior.FIT_AND_CROP_BOX ||
    !Number.isSafeInteger(value.layoutBehavior)) {
    throw new Error('page PDF background header is invalid');
  }
  validateAssetMetadata(value.metadata);
  for (const crop of value.cropBoxes) {
    if (!isNonNegativeFinite(crop.widthPt) || !isNonNegativeFinite(crop.heightPt)) {
      throw new Error('page PDF crop box is invalid');
    }
  }
}

function validateAssetMetadata(value: OriginalAssetMetadata): void {
  if (!Array.isArray(value.assetHashBits) || value.assetHashBits.length !== 8 ||
    value.fileName.length === 0 || value.mimeType.length === 0 ||
    !isUint32(value.fileSize) || value.fileSize === 0) {
    throw new Error('page PDF asset metadata is invalid');
  }
  for (const word of value.assetHashBits) {
    if (typeof word !== 'string' || word.length === 0 || word.length > 20 ||
      !/^\d+$/.test(word) || (word.length > 1 && word.charAt(0) === '0') ||
      (word.length === 20 && word > '18446744073709551615')) {
      throw new Error('page PDF asset hash is invalid');
    }
  }
}

function cloneMargins(value: PageBackgroundMargins | null): PageBackgroundMargins | null {
  if (value === null) {
    return null;
  }
  return { topPt: value.topPt, bottomPt: value.bottomPt, leftPt: value.leftPt, rightPt: value.rightPt };
}

export function validateOriginalPaper(value: PagePaperBackground | null): void {
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

function isUint32(value: number): boolean {
  return Number.isSafeInteger(value) && value >= 0 && value <= 4294967295;
}

function isOptionalBoolean(value: boolean | null): boolean {
  return value === null || typeof value === 'boolean';
}

function isOptionalByte(value: number | null): boolean {
  return value === null || (Number.isSafeInteger(value) && value >= 0 && value <= 255);
}
