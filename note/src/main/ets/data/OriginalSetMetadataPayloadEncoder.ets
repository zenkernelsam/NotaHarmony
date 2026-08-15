import { util } from '@kit.ArkTS';
import { validateOriginalNoteTitleWireValue } from '../core/model/OriginalNoteTitlePolicy';
import { originalAssetStorageHash } from '../core/model/ImageBlockGeometry';
import {
  PageBackground, PagePaperBackground, PagePdfBackground, PdfLayoutBehavior,
} from '../core/model/NoteTypes';
import { validatePageBackground } from '../core/model/PageBackgroundModel';

const MAX_ASSET_FILE_NAME_BYTES: number = 65536;
const MAX_ASSET_MIME_TYPE_BYTES: number = 4096;
const MAX_TITLE_BYTES: number = 1024;

interface PdfEncoding {
  value: PagePdfBackground;
  fileName: Uint8Array;
  mimeType: Uint8Array;
}

interface BackgroundLayout {
  rootVtable: number;
  rootTable: number;
  setterVtable: number;
  setterTable: number;
  backgroundVtable: number;
  backgroundTable: number;
  paperVtable: number;
  paperTable: number;
  pdfVtable: number;
  pdfTable: number;
  metadataVtable: number;
  metadataTable: number;
  cropVector: number;
  fileNameVector: number;
  mimeTypeVector: number;
  total: number;
}

// Original 1.0.3 wire chain:
// l2d SetMetadata.field1 -> m2d SetPageBackground.field0 -> nz9 PageBackground.
// The m2d table is deliberately retained when value is null: null resets the note-level
// register to the original Letter fallback, while an absent m2d means "do not edit it".
export function encodeOriginalSetMetadataPageBackground(
  background: PageBackground | null): Uint8Array {
  validatePageBackground(background);
  const pdf: PdfEncoding | null = background === null || background.pdf === undefined ||
    background.pdf === null ? null : preparePdf(background.pdf);
  const layout: BackgroundLayout = planLayout(background, pdf);
  const bytes: Uint8Array = new Uint8Array(layout.total);

  writeU32(bytes, 0, layout.rootTable);
  writeVtable(bytes, layout.rootVtable, 8, [0, 4, 0, 0, 0, 0, 0, 0]);
  writeU32(bytes, layout.rootTable, layout.rootTable - layout.rootVtable);
  writeU32(bytes, layout.rootTable + 4, layout.setterTable - (layout.rootTable + 4));

  writeVtable(bytes, layout.setterVtable, 8, [background === null ? 0 : 4]);
  writeU32(bytes, layout.setterTable, layout.setterTable - layout.setterVtable);
  if (background === null) {
    return bytes;
  }
  writeU32(bytes, layout.setterTable + 4,
    layout.backgroundTable - (layout.setterTable + 4));
  writeBackground(bytes, layout, background, pdf);
  return bytes;
}

// Original 1.0.3 wire chain:
// l2d SetMetadata.field0 -> z2d SetString.field0 -> UTF-8 title.
// A title-only operation leaves l2d.field1 absent; that is not a background reset.
export function encodeOriginalSetMetadataTitle(title: string): Uint8Array {
  validateOriginalNoteTitleWireValue(title);
  const encoder: util.TextEncoder = new util.TextEncoder();
  const encoded: Uint8Array = encoder.encodeInto(title);
  if (encoded.length === 0 || encoded.length > MAX_TITLE_BYTES ||
    !validUtf8RoundTrip(encoded, title)) {
    throw new Error('local SET_METADATA title UTF-8 is invalid');
  }
  const rootVtable: number = 4;
  const rootTable: number = 24;
  const setterVtable: number = 32;
  const setterTable: number = 40;
  const titleVector: number = 48;
  const bytes: Uint8Array = new Uint8Array(
    align4(titleVector + 4 + encoded.length + 1));

  writeU32(bytes, 0, rootTable);
  writeVtable(bytes, rootVtable, 8, [4, 0, 0, 0, 0, 0, 0, 0]);
  writeU32(bytes, rootTable, rootTable - rootVtable);
  writeU32(bytes, rootTable + 4, setterTable - (rootTable + 4));

  writeVtable(bytes, setterVtable, 8, [4]);
  writeU32(bytes, setterTable, setterTable - setterVtable);
  writeU32(bytes, setterTable + 4, titleVector - (setterTable + 4));
  writeString(bytes, titleVector, encoded);
  return bytes;
}

function preparePdf(value: PagePdfBackground): PdfEncoding {
  const encoder: util.TextEncoder = new util.TextEncoder();
  const fileName: Uint8Array = encoder.encodeInto(value.metadata.fileName);
  const mimeType: Uint8Array = encoder.encodeInto(value.metadata.mimeType);
  if (fileName.length === 0 || fileName.length > MAX_ASSET_FILE_NAME_BYTES ||
    !validUtf8RoundTrip(fileName, value.metadata.fileName) || mimeType.length === 0 ||
    mimeType.length > MAX_ASSET_MIME_TYPE_BYTES ||
    !validUtf8RoundTrip(mimeType, value.metadata.mimeType)) {
    throw new Error('local SET_METADATA PDF asset strings are invalid');
  }
  return { value: value, fileName: fileName, mimeType: mimeType };
}

function planLayout(background: PageBackground | null,
  pdf: PdfEncoding | null): BackgroundLayout {
  const rootVtable: number = 4;
  const rootTable: number = 24;
  const setterVtable: number = 32;
  const setterTable: number = 40;
  if (background === null) {
    return emptyLayout(rootVtable, rootTable, setterVtable, setterTable, 48);
  }
  const backgroundVtable: number = 48;
  const backgroundTable: number = 64;
  let cursor: number = backgroundTable + 40;
  let paperVtable: number = 0;
  let paperTable: number = 0;
  if (background.paper !== null) {
    paperVtable = cursor;
    paperTable = align4(paperVtable + 16);
    cursor = paperTable + 16;
  }
  let pdfVtable: number = 0;
  let pdfTable: number = 0;
  let metadataVtable: number = 0;
  let metadataTable: number = 0;
  let cropVector: number = 0;
  let fileNameVector: number = 0;
  let mimeTypeVector: number = 0;
  if (pdf !== null) {
    pdfVtable = cursor;
    pdfTable = align4(pdfVtable + 16);
    metadataVtable = pdfTable + 28;
    metadataTable = align4(metadataVtable + 12);
    cropVector = align4(metadataTable + 80);
    fileNameVector = align4(cropVector + 4 + pdf.value.cropBoxes.length * 8);
    mimeTypeVector = align4(fileNameVector + 4 + pdf.fileName.length + 1);
    cursor = mimeTypeVector + 4 + pdf.mimeType.length + 1;
  }
  return {
    rootVtable: rootVtable, rootTable: rootTable,
    setterVtable: setterVtable, setterTable: setterTable,
    backgroundVtable: backgroundVtable, backgroundTable: backgroundTable,
    paperVtable: paperVtable, paperTable: paperTable,
    pdfVtable: pdfVtable, pdfTable: pdfTable,
    metadataVtable: metadataVtable, metadataTable: metadataTable,
    cropVector: cropVector, fileNameVector: fileNameVector, mimeTypeVector: mimeTypeVector,
    total: align4(cursor),
  };
}

function emptyLayout(rootVtable: number, rootTable: number, setterVtable: number,
  setterTable: number, total: number): BackgroundLayout {
  return {
    rootVtable: rootVtable, rootTable: rootTable,
    setterVtable: setterVtable, setterTable: setterTable,
    backgroundVtable: 0, backgroundTable: 0, paperVtable: 0, paperTable: 0,
    pdfVtable: 0, pdfTable: 0, metadataVtable: 0, metadataTable: 0,
    cropVector: 0, fileNameVector: 0, mimeTypeVector: 0, total: total,
  };
}

function writeBackground(bytes: Uint8Array, layout: BackgroundLayout,
  background: PageBackground, pdf: PdfEncoding | null): void {
  const hasRotation: boolean = background.rotationRadians !== 0;
  const hasSize: boolean = background.sourceWidthPt !== null;
  const fields: number[] = [
    background.paper === null ? 0 : 4,
    pdf === null ? 0 : 8,
    hasRotation ? 12 : 0,
    hasSize ? 16 : 0,
    background.margins === null ? 0 : 24,
  ];
  writeVtable(bytes, layout.backgroundVtable, 40, fields);
  writeU32(bytes, layout.backgroundTable,
    layout.backgroundTable - layout.backgroundVtable);
  if (background.paper !== null) {
    writeU32(bytes, layout.backgroundTable + 4,
      layout.paperTable - (layout.backgroundTable + 4));
  }
  if (pdf !== null) {
    writeU32(bytes, layout.backgroundTable + 8,
      layout.pdfTable - (layout.backgroundTable + 8));
  }
  if (hasRotation) {
    writeF32(bytes, layout.backgroundTable + 12, background.rotationRadians);
  }
  if (hasSize) {
    writeF32(bytes, layout.backgroundTable + 16, background.sourceWidthPt as number);
    writeF32(bytes, layout.backgroundTable + 20, background.sourceHeightPt as number);
  }
  if (background.margins !== null) {
    writeF32(bytes, layout.backgroundTable + 24, background.margins.topPt);
    writeF32(bytes, layout.backgroundTable + 28, background.margins.bottomPt);
    writeF32(bytes, layout.backgroundTable + 32, background.margins.leftPt);
    writeF32(bytes, layout.backgroundTable + 36, background.margins.rightPt);
  }
  if (background.paper !== null) {
    writePaper(bytes, layout.paperVtable, layout.paperTable, background.paper);
  }
  if (pdf !== null) {
    writePdf(bytes, layout, pdf);
  }
}

function writePaper(bytes: Uint8Array, vtable: number, table: number,
  paper: PagePaperBackground): void {
  const fields: number[] = [
    paper.flair === null ? 0 : 4,
    paper.flairSpacingPt === null ? 0 : 8,
    paper.flairBleeds === null ? 0 : 5,
    paper.flairCentered === null ? 0 : 6,
    paper.colorR === null ? 0 : 12,
    paper.legacyPaperIndex === null ? 0 : 7,
  ];
  writeVtable(bytes, vtable, 16, fields);
  writeU32(bytes, table, table - vtable);
  if (paper.flair !== null) {
    writeU8(bytes, table + 4, paper.flair);
  }
  if (paper.flairBleeds !== null) {
    writeU8(bytes, table + 5, paper.flairBleeds ? 1 : 0);
  }
  if (paper.flairCentered !== null) {
    writeU8(bytes, table + 6, paper.flairCentered ? 1 : 0);
  }
  if (paper.legacyPaperIndex !== null) {
    writeU8(bytes, table + 7, paper.legacyPaperIndex);
  }
  if (paper.flairSpacingPt !== null) {
    writeF32(bytes, table + 8, paper.flairSpacingPt);
  }
  if (paper.colorR !== null) {
    writeU8(bytes, table + 12, paper.colorR);
    writeU8(bytes, table + 13, paper.colorG as number);
    writeU8(bytes, table + 14, paper.colorB as number);
    writeU8(bytes, table + 15, paper.colorA as number);
  }
}

function writePdf(bytes: Uint8Array, layout: BackgroundLayout,
  encoded: PdfEncoding): void {
  const pdf: PagePdfBackground = encoded.value;
  const fields: number[] = [
    4,
    pdf.layoutBehavior === PdfLayoutBehavior.FIT_AND_CROP_BOX ? 0 : 8,
    pdf.totalPageCount === 1 ? 0 : 12,
    pdf.pagesConsumed === 1 ? 0 : 16,
    pdf.pageOffset === 0 ? 0 : 20,
    24,
  ];
  writeVtable(bytes, layout.pdfVtable, 28, fields);
  writeU32(bytes, layout.pdfTable, layout.pdfTable - layout.pdfVtable);
  writeU32(bytes, layout.pdfTable + 4,
    layout.metadataTable - (layout.pdfTable + 4));
  if (fields[1] !== 0) {
    writeU8(bytes, layout.pdfTable + 8, pdf.layoutBehavior);
  }
  if (fields[2] !== 0) {
    writeU32(bytes, layout.pdfTable + 12, pdf.totalPageCount);
  }
  if (fields[3] !== 0) {
    writeU32(bytes, layout.pdfTable + 16, pdf.pagesConsumed);
  }
  if (fields[4] !== 0) {
    writeU32(bytes, layout.pdfTable + 20, pdf.pageOffset);
  }
  writeU32(bytes, layout.pdfTable + 24,
    layout.cropVector - (layout.pdfTable + 24));

  writeVtable(bytes, layout.metadataVtable, 80, [4, 68, 72, 76]);
  writeU32(bytes, layout.metadataTable,
    layout.metadataTable - layout.metadataVtable);
  writeHash(bytes, layout.metadataTable + 4, pdf.metadata.assetHashBits);
  writeU32(bytes, layout.metadataTable + 68,
    layout.fileNameVector - (layout.metadataTable + 68));
  writeU32(bytes, layout.metadataTable + 72,
    layout.mimeTypeVector - (layout.metadataTable + 72));
  writeU32(bytes, layout.metadataTable + 76, pdf.metadata.fileSize);

  writeU32(bytes, layout.cropVector, pdf.cropBoxes.length);
  for (let index: number = 0; index < pdf.cropBoxes.length; index++) {
    const offset: number = layout.cropVector + 4 + index * 8;
    writeF32(bytes, offset, pdf.cropBoxes[index].widthPt);
    writeF32(bytes, offset + 4, pdf.cropBoxes[index].heightPt);
  }
  writeString(bytes, layout.fileNameVector, encoded.fileName);
  writeString(bytes, layout.mimeTypeVector, encoded.mimeType);
}

function writeHash(bytes: Uint8Array, offset: number, bits: string[]): void {
  const hex: string = originalAssetStorageHash(bits);
  for (let index: number = 0; index < 64; index++) {
    bytes[offset + index] = parseInt(hex.substring(index * 2, index * 2 + 2), 16);
  }
}

function writeString(bytes: Uint8Array, offset: number, value: Uint8Array): void {
  writeU32(bytes, offset, value.length);
  bytes.set(value, offset + 4);
  bytes[offset + 4 + value.length] = 0;
}

function validUtf8RoundTrip(bytes: Uint8Array, value: string): boolean {
  return util.TextDecoder.create('utf-8').decodeToString(bytes) === value;
}

function writeVtable(bytes: Uint8Array, offset: number, objectSize: number,
  fields: number[]): void {
  writeU16(bytes, offset, 4 + fields.length * 2);
  writeU16(bytes, offset + 2, objectSize);
  for (let index: number = 0; index < fields.length; index++) {
    writeU16(bytes, offset + 4 + index * 2, fields[index]);
  }
}

function writeF32(bytes: Uint8Array, offset: number, value: number): void {
  new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(offset, value, true);
}

function writeU8(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
}

function align4(value: number): number {
  return (value + 3) & ~3;
}

function writeU16(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = value >>> 8 & 0xFF;
}

function writeU32(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = value >>> 8 & 0xFF;
  bytes[offset + 2] = value >>> 16 & 0xFF;
  bytes[offset + 3] = value >>> 24 & 0xFF;
}
