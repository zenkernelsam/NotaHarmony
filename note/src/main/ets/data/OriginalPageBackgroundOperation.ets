import {
  OriginalPaperFlair, PageBackground, PageBackgroundMargins, PageOrientation, PagePaperBackground,
  PaperSize, PaperTemplate,
} from '../core/model/NoteTypes';
import {
  PAGE_BACKGROUND_SCHEMA_VERSION, POINTS_TO_MM, templateForOriginalPaper, validatePageBackground,
} from '../core/model/PageBackgroundModel';
import { pagePixelSize } from '../core/model/PageCoordinateSpace';
import {
  OriginalFlatBufferTableReader, readOriginalInlineFloat32,
} from './OriginalSyncedOperationFlatBuffer';

export interface OriginalDecodedPageBackground {
  background: PageBackground;
  template: PaperTemplate;
  size: PaperSize;
  orientation: PageOrientation;
  widthMm: number;
  heightMm: number;
  hasPdf: boolean;
}

export function decodeOriginalPageBackgroundTable(
  table: OriginalFlatBufferTableReader): OriginalDecodedPageBackground {
  const paperTable: OriginalFlatBufferTableReader | null = table.readTable(0);
  const paper: PagePaperBackground | null = paperTable === null ? null : decodePaper(paperTable);
  const hasPdf: boolean = table.readTable(1) !== null;
  const rotation: number = normalizeCardinalRotation(table.readFloat32(2, 0));
  const sourceSize: number[] | null = readInlineFloats(table, 3, 2);
  const marginsRaw: number[] | null = readInlineFloats(table, 4, 4);
  const margins: PageBackgroundMargins | null = marginsRaw === null ? null : {
    topPt: marginsRaw[0], bottomPt: marginsRaw[1], leftPt: marginsRaw[2], rightPt: marginsRaw[3],
  };
  const background: PageBackground = {
    schemaVersion: PAGE_BACKGROUND_SCHEMA_VERSION,
    paper: paper,
    rotationRadians: rotation,
    sourceWidthPt: sourceSize === null ? null : sourceSize[0],
    sourceHeightPt: sourceSize === null ? null : sourceSize[1],
    margins: margins,
  };
  validatePageBackground(background);
  const swap: boolean = near(rotation, Math.PI / 2) || near(rotation, Math.PI * 3 / 2);
  const sourceWidthMm: number = sourceSize === null ? 215.9 : sourceSize[0] * POINTS_TO_MM;
  const sourceHeightMm: number = sourceSize === null ? 279.4 : sourceSize[1] * POINTS_TO_MM;
  const widthMm: number = swap ? sourceHeightMm : sourceWidthMm;
  const heightMm: number = swap ? sourceWidthMm : sourceHeightMm;
  return {
    background: background,
    template: templateForOriginalPaper(paper),
    size: PaperSize.LETTER,
    orientation: widthMm > heightMm ? PageOrientation.LANDSCAPE : PageOrientation.PORTRAIT,
    widthMm: widthMm,
    heightMm: heightMm,
    hasPdf: hasPdf,
  };
}

export function originalPageBackgroundFitsHarmony(value: OriginalDecodedPageBackground): boolean {
  try {
    pagePixelSize(value.widthMm, value.heightMm);
    return true;
  } catch (_error) {
    return false;
  }
}

function decodePaper(table: OriginalFlatBufferTableReader): PagePaperBackground {
  const color: Uint8Array | null = table.readInlineBytes(4, 4);
  const flairValue: number | null = table.hasField(0) ? table.readUint8(0, 0) : null;
  if (flairValue !== null && (flairValue < OriginalPaperFlair.LINES ||
    flairValue > OriginalPaperFlair.GRID)) {
    throw new Error('original paper flair is unknown');
  }
  const spacing: number | null = table.hasField(1) ? table.readFloat32(1, 0) : null;
  return {
    flair: flairValue as OriginalPaperFlair | null,
    // q7j treats non-finite spacing as no grid; normalize to that semantic value
    // because JSON and SQLite cannot preserve a useful non-finite spacing.
    flairSpacingPt: spacing !== null && Number.isFinite(spacing) ? spacing : null,
    flairBleeds: table.hasField(2) ? table.readUint8(2, 0) !== 0 : null,
    flairCentered: table.hasField(3) ? table.readUint8(3, 0) !== 0 : null,
    colorR: color === null ? null : color[0],
    colorG: color === null ? null : color[1],
    colorB: color === null ? null : color[2],
    colorA: color === null ? null : color[3],
    legacyPaperIndex: table.hasField(5) ? table.readUint8(5, 0) : null,
  };
}

function readInlineFloats(table: OriginalFlatBufferTableReader, field: number,
  count: number): number[] | null {
  const bytes: Uint8Array | null = table.readInlineBytes(field, count * 4);
  if (bytes === null) {
    return null;
  }
  const result: number[] = [];
  for (let index: number = 0; index < count; index++) {
    result.push(readOriginalInlineFloat32(bytes, index * 4));
  }
  return result;
}

function normalizeCardinalRotation(value: number): number {
  if (near(value, 0)) {
    return 0;
  }
  if (near(value, Math.PI / 2)) {
    return Math.PI / 2;
  }
  if (near(value, Math.PI)) {
    return Math.PI;
  }
  if (near(value, Math.PI * 3 / 2)) {
    return Math.PI * 3 / 2;
  }
  throw new Error('original page background rotation is not cardinal');
}

function near(left: number, right: number): boolean {
  return Math.abs(left - right) < 0.0001;
}
