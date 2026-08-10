import { relationalStore } from '@kit.ArkData';
import { ElementType, ImageElement, MathElement, TextBlockElement } from '../core/model/ElementTypes';
import { TransformMatrix } from '../core/model/GeometryTypes';
import { AssetStatus } from '../core/model/AssetTypes';
import { imageBlockWorldBounds, originalAssetHashKey,
  originalAssetStorageHash } from '../core/model/ImageBlockGeometry';
import { PagePaperBackground } from '../core/model/NoteTypes';
import { cloneOriginalPaper } from '../core/model/PageBackgroundModel';
import { PageElementKind } from '../core/model/PageElementOrder';
import { textBlockWorldBounds } from '../core/model/TextBlockGeometry';
import { mathBlockWorldBounds } from '../core/model/MathBlockGeometry';
import { encodeOperationId, OriginalSequenceIdentity,
  validateOriginalSequenceIdentity } from './OperationIdentity';
import { encodePersistedElement, PersistedElement } from './StrokePersistence';
import { SearchItemType } from './SearchItemType';
import { OriginalFlatBufferTableReader, readOriginalInlineFloat32,
  readOriginalInlineUint64Decimal, readOriginalPayloadTable } from
  './OriginalSyncedOperationFlatBuffer';
import { decodeOriginalPaper } from './OriginalPageBackgroundOperation';
import { StoredSyncedOperation, SyncedOperationApplier,
  SyncedOperationApplyResult } from './SyncedOperationInbox';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';
import { mergeNoteIds, parseAssetNoteIds } from './AssetRepositoryImpl';

export const ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE: number = 22;

export enum OriginalBlockType {
  TEXT = 0,
  IMAGE = 1,
  MATH = 2,
}

export interface OriginalBlockMargins {
  top: number;
  bottom: number;
  left: number;
  right: number;
}

export interface OriginalAssetHash {
  bits: string[];
}

export interface OriginalImageAsset {
  assetHash: OriginalAssetHash;
  fileName: string;
  mimeType: string;
  fileSize: number;
  width: number;
  height: number;
}

export interface OriginalBlockRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface OriginalCreateBlockPayload {
  blockType: OriginalBlockType;
  corner: number;
  page: OriginalSequenceIdentity;
  originX: number;
  originY: number;
  rotation: number | null;
  scaleX: number | null;
  scaleY: number | null;
  width: number;
  height: number;
  textWrap: number;
  enableCaption: boolean;
  zIndex: string;
  image: OriginalImageAsset | null;
  cropRect: OriginalBlockRect | null;
  webUrl: string | null;
  hasImage: boolean;
  hasCropRect: boolean;
  hasWebUrl: boolean;
  hasMathLatex: boolean;
  hasMathColor: boolean;
  mathLatex: string | null;
  mathColor: number | null;
  paper: PagePaperBackground | null;
  imageFlippedHorizontally: boolean;
  imageFlippedVertically: boolean;
  resizesWidthToFitText: boolean;
  margins: OriginalBlockMargins;
  positionLocked: boolean;
}

const MAX_ORIGINAL_ASSET_FILE_NAME_BYTES: number = 65536;
const MAX_ORIGINAL_ASSET_MIME_TYPE_BYTES: number = 4096;
const MAX_ORIGINAL_BLOCK_WEB_URL_BYTES: number = 1048576;
const MAX_ORIGINAL_MATH_LATEX_BYTES: number = 1048576;

interface StoredTargetPage {
  pageId: string;
  table: string;
  revision: number;
  archived: boolean;
}

interface StoredZIndexRow {
  elementId: string;
  kind: number;
  timestamp: number;
  siteId: number;
  zIndex: string;
}

interface StoredAssetRow {
  assetHash: string;
  status: number;
  noteIds: string[];
  fileSize: number;
  mimeType: string;
  localPath: string | null;
}

export function decodeOriginalCreateBlock(bytes: Uint8Array,
  defaultZIndex: string): OriginalCreateBlockPayload {
  const table: OriginalFlatBufferTableReader = readOriginalPayloadTable(
    bytes, ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE);
  return decodeOriginalCreateBlockTable(table, defaultZIndex);
}

export function decodeOriginalCreateBlockTable(table: OriginalFlatBufferTableReader,
  defaultZIndex: string): OriginalCreateBlockPayload {
  validateUnsignedLongDecimal(defaultZIndex);
  const rawPage: number[] | null = table.readInlineSequence(2);
  const origin: Uint8Array | null = table.readInlineBytes(3, 8);
  const size: Uint8Array | null = table.readInlineBytes(6, 8);
  if (rawPage === null || origin === null || size === null) {
    throw new Error('original create-block is missing a required inline field');
  }
  const page: OriginalSequenceIdentity = {
    timestamp: rawPage[0], siteId: rawPage[1], index: rawPage[2],
  };
  validateOriginalSequenceIdentity(page);
  const scale: Uint8Array | null = table.readInlineBytes(5, 8);
  const marginBytes: Uint8Array | null = table.readInlineBytes(19, 16);
  const margins: OriginalBlockMargins = marginBytes === null ? {
    top: 3, bottom: 10, left: 5, right: 5,
  } : {
    top: readOriginalInlineFloat32(marginBytes, 0),
    bottom: readOriginalInlineFloat32(marginBytes, 4),
    left: readOriginalInlineFloat32(marginBytes, 8),
    right: readOriginalInlineFloat32(marginBytes, 12),
  };
  const zIndex: string = table.readUint64Decimal(9, defaultZIndex) as string;
  const paperTable: OriginalFlatBufferTableReader | null = table.readTable(15);
  const imageTable: OriginalFlatBufferTableReader | null = table.readTable(10);
  const image: OriginalImageAsset | null = imageTable === null ? null :
    decodeOriginalImageAsset(imageTable);
  const cropBytes: Uint8Array | null = table.readInlineBytes(11, 16);
  const cropRect: OriginalBlockRect | null = cropBytes === null ? null : {
    x: readOriginalInlineFloat32(cropBytes, 0),
    y: readOriginalInlineFloat32(cropBytes, 4),
    width: readOriginalInlineFloat32(cropBytes, 8),
    height: readOriginalInlineFloat32(cropBytes, 12),
  };
  if (cropRect !== null && !validRect(cropRect)) {
    throw new Error('original create-block crop rect is invalid');
  }
  const webUrl: string | null = table.readUtf8String(
    12, false, MAX_ORIGINAL_BLOCK_WEB_URL_BYTES);
  const blockType: OriginalBlockType = normalizeOriginalEnum(
    table.readUint8(0, 0), 2) as OriginalBlockType;
  if (blockType === OriginalBlockType.IMAGE && image === null) {
    throw new Error('original image block has no required image asset');
  }
  validateUnsignedLongDecimal(zIndex);
  const mathColorBytes: Uint8Array | null = table.readInlineBytes(14, 4);
  return {
    blockType: blockType,
    corner: normalizeOriginalEnum(table.readUint8(1, 0), 1),
    page: page,
    originX: readOriginalInlineFloat32(origin, 0),
    originY: readOriginalInlineFloat32(origin, 4),
    rotation: table.hasField(4) ? table.readFloat32(4, 0) : null,
    scaleX: scale === null ? null : readOriginalInlineFloat32(scale, 0),
    scaleY: scale === null ? null : readOriginalInlineFloat32(scale, 4),
    width: readOriginalInlineFloat32(size, 0),
    height: readOriginalInlineFloat32(size, 4),
    textWrap: normalizeOriginalEnum(table.readUint8(7, 0), 1),
    enableCaption: table.readUint8(8, 0) !== 0,
    zIndex: zIndex,
    image: image,
    cropRect: cropRect,
    webUrl: webUrl,
    hasImage: image !== null,
    hasCropRect: cropRect !== null,
    hasWebUrl: webUrl !== null,
    hasMathLatex: table.hasField(13),
    hasMathColor: table.hasField(14),
    mathLatex: table.readUtf8String(13, false, MAX_ORIGINAL_MATH_LATEX_BYTES),
    mathColor: mathColorBytes === null ? null : rgbaBytesToArgb(mathColorBytes),
    paper: paperTable === null ? null : decodeOriginalPaper(paperTable),
    imageFlippedHorizontally: table.readUint8(16, 0) !== 0,
    imageFlippedVertically: table.readUint8(17, 0) !== 0,
    resizesWidthToFitText: table.readUint8(18, 0) !== 0,
    margins: margins,
    positionLocked: table.readUint8(20, 0) !== 0,
  };
}

export function unsupportedOriginalCreateBlockReason(
  payload: OriginalCreateBlockPayload): string | null {
  const hasImageFields: boolean = payload.hasImage || payload.hasCropRect || payload.hasWebUrl ||
    payload.imageFlippedHorizontally || payload.imageFlippedVertically;
  const hasMathFields: boolean = payload.hasMathLatex || payload.hasMathColor;
  if (payload.blockType !== OriginalBlockType.IMAGE && hasImageFields) {
    return payload.blockType === OriginalBlockType.MATH ?
      'CREATE_BLOCK_IMAGE_FIELDS_ON_MATH' : 'CREATE_BLOCK_IMAGE_FIELDS_ON_TEXT';
  }
  if (payload.blockType !== OriginalBlockType.MATH && hasMathFields) {
    return payload.blockType === OriginalBlockType.IMAGE ?
      'CREATE_BLOCK_MATH_FIELDS_ON_IMAGE' : 'CREATE_BLOCK_MATH_FIELDS_ON_TEXT';
  }
  if (payload.blockType !== OriginalBlockType.TEXT && payload.paper !== null) {
    return payload.blockType === OriginalBlockType.IMAGE ?
      'CREATE_BLOCK_TEXT_PAPER_ON_IMAGE' : 'CREATE_BLOCK_TEXT_PAPER_ON_MATH';
  }
  if (payload.blockType === OriginalBlockType.IMAGE && payload.image === null) {
    return 'CREATE_BLOCK_IMAGE_MISSING_ASSET';
  }
  if (payload.blockType === OriginalBlockType.MATH &&
    (!payload.hasMathLatex || !payload.hasMathColor ||
      payload.mathLatex === null || payload.mathColor === null)) {
    return 'CREATE_BLOCK_MATH_FIELDS_MISSING';
  }
  if (!Number.isFinite(payload.originX) || !Number.isFinite(payload.originY) ||
    (payload.rotation !== null && !Number.isFinite(payload.rotation)) ||
    (payload.scaleX !== null && !Number.isFinite(payload.scaleX)) ||
    (payload.scaleY !== null && !Number.isFinite(payload.scaleY))) {
    return 'CREATE_BLOCK_TRANSFORM_UNSUPPORTED';
  }
  if (!Number.isFinite(payload.width) || !Number.isFinite(payload.height) ||
    payload.width < 0 || payload.height < 0) {
    return 'CREATE_BLOCK_SIZE_UNSUPPORTED';
  }
  if (!validMargins(payload.margins)) {
    return 'CREATE_BLOCK_MARGINS_UNSUPPORTED';
  }
  return null;
}

export class OriginalCreateBlockOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalCreateBlockPayload;
    try {
      payload = decodeOriginalCreateBlock(operation.rawOperation, operation.clientTime);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_CREATE_BLOCK_PAYLOAD' };
    }
    return this.applyPayload(store, operation, payload);
  }

  preflightTable(table: OriginalFlatBufferTableReader, defaultZIndex: string): string | null {
    let payload: OriginalCreateBlockPayload;
    try {
      payload = decodeOriginalCreateBlockTable(table, defaultZIndex);
    } catch (_error) {
      return 'MALFORMED_CREATE_BLOCK_PAYLOAD';
    }
    return unsupportedOriginalCreateBlockReason(payload);
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    let payload: OriginalCreateBlockPayload;
    try {
      payload = decodeOriginalCreateBlockTable(table, operation.clientTime);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_CREATE_BLOCK_PAYLOAD' };
    }
    return this.applyPayload(store, operation, payload);
  }

  private async applyPayload(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    payload: OriginalCreateBlockPayload): Promise<SyncedOperationApplyResult> {
    const unsupported: string | null = unsupportedOriginalCreateBlockReason(payload);
    if (unsupported !== null) {
      return { deferredReason: unsupported };
    }
    const target: StoredTargetPage | null = await this.readTargetPage(
      store, operation, payload.page);
    if (target === null) {
      return { deferredReason: 'CREATE_BLOCK_PAGE_MISSING_OR_UNBOUND' };
    }
    if (await this.originalElementExists(store, operation)) {
      if (await this.originalCreateMatches(store, operation, payload)) {
        return { deferredReason: null };
      }
      throw new Error('original create-block identity conflicts with persisted state');
    }
    const existingRows: StoredZIndexRow[] | null = await this.readCompleteOriginalOrder(
      store, operation.noteId, payload.page, target);
    if (existingRows === null) {
      return { deferredReason: 'CREATE_BLOCK_ELEMENT_ORDER_DIVERGED' };
    }
    if (target.revision >= Number.MAX_SAFE_INTEGER) {
      return { deferredReason: 'CREATE_BLOCK_PAGE_REVISION_EXHAUSTED' };
    }

    const kind: PageElementKind = payload.blockType === OriginalBlockType.IMAGE ?
      PageElementKind.IMAGE : payload.blockType === OriginalBlockType.MATH ?
        PageElementKind.MATH : PageElementKind.TEXT;
    const element: TextBlockElement | ImageElement | MathElement =
      payload.blockType === OriginalBlockType.IMAGE ? this.buildImageBlock(operation, payload) :
        payload.blockType === OriginalBlockType.MATH ? this.buildMathBlock(operation, payload) :
          this.buildTextBlock(operation, payload);
    if (payload.blockType === OriginalBlockType.IMAGE) {
      const assetReason: string | null = await this.mergeImageAssetReference(
        store, operation.noteId, payload.image as OriginalImageAsset);
      if (assetReason !== null) {
        return { deferredReason: assetReason };
      }
    }
    await store.insert('original_element_z_index', {
      'note_id': operation.noteId,
      'element_timestamp': operation.timestamp,
      'element_site_id': operation.siteId,
      'page_timestamp': payload.page.timestamp,
      'page_site_id': payload.page.siteId,
      'page_index': payload.page.index,
      'kind': kind,
      'z_index': payload.zIndex,
    });
    await store.insert('original_block_state', {
      'note_id': operation.noteId,
      'block_timestamp': operation.timestamp,
      'block_site_id': operation.siteId,
      'block_type': payload.blockType,
      'create_page_timestamp': payload.page.timestamp,
      'create_page_site_id': payload.page.siteId,
      'create_page_index': payload.page.index,
      'create_origin_x': payload.originX,
      'create_origin_y': payload.originY,
      'create_rotation': payload.rotation,
      'create_scale_x': payload.scaleX,
      'create_scale_y': payload.scaleY,
      'create_width': payload.width,
      'create_height': payload.height,
      'create_corner': payload.corner,
      'create_text_wrap': payload.textWrap,
      'create_enable_caption': payload.enableCaption ? 1 : 0,
      'create_position_locked': payload.positionLocked ? 1 : 0,
      'create_resizes_width': payload.resizesWidthToFitText ? 1 : 0,
      'create_text_paper': payload.paper === null ? null : JSON.stringify(payload.paper),
      'create_math_latex': payload.mathLatex,
      'create_math_color': payload.mathColor,
      'create_image_hash_bits': payload.image === null ? null :
        JSON.stringify(payload.image.assetHash.bits),
      'create_image_file_name': payload.image === null ? null : payload.image.fileName,
      'create_image_mime_type': payload.image === null ? null : payload.image.mimeType,
      'create_image_file_size': payload.image === null ? null : payload.image.fileSize,
      'create_image_width': payload.image === null ? null : payload.image.width,
      'create_image_height': payload.image === null ? null : payload.image.height,
      'create_image_crop_x': payload.cropRect === null ? null : payload.cropRect.x,
      'create_image_crop_y': payload.cropRect === null ? null : payload.cropRect.y,
      'create_image_crop_width': payload.cropRect === null ? null : payload.cropRect.width,
      'create_image_crop_height': payload.cropRect === null ? null : payload.cropRect.height,
      'create_image_web_url': payload.webUrl,
      'create_image_flipped_horizontally': payload.image === null ? null :
        (payload.imageFlippedHorizontally ? 1 : 0),
      'create_image_flipped_vertically': payload.image === null ? null :
        (payload.imageFlippedVertically ? 1 : 0),
      'create_margin_top': payload.margins.top,
      'create_margin_bottom': payload.margins.bottom,
      'create_margin_left': payload.margins.left,
      'create_margin_right': payload.margins.right,
      'create_z_index': payload.zIndex,
    });
    existingRows.push({
      elementId: element.id, kind: kind,
      timestamp: operation.timestamp, siteId: operation.siteId, zIndex: payload.zIndex,
    });
    existingRows.sort(compareStoredZIndexRows);
    await this.materializeOrder(store, operation.noteId, payload.page, target,
      existingRows, element, kind, target.revision + 1);
    return { deferredReason: null };
  }

  private buildTextBlock(operation: StoredSyncedOperation,
    payload: OriginalCreateBlockPayload): TextBlockElement {
    const rotation: number = payload.rotation === null ? 0 : payload.rotation;
    const scaleX: number = payload.scaleX === null ? 1 : payload.scaleX;
    const scaleY: number = payload.scaleY === null ? 1 : payload.scaleY;
    const transform: TransformMatrix = blockTransform(
      payload.originX, payload.originY, rotation, scaleX, scaleY);
    const text: TextBlockElement = {
      id: encodeOperationId(operation),
      type: ElementType.TEXT,
      transform: transform,
      bounds: { left: 0, top: 0, right: 0, bottom: 0 },
      richText: '',
      textOrigin: { x: 0, y: 0 },
      blockWidth: payload.width,
      blockHeight: payload.height,
      rotationRadians: rotation,
      contentLeftInset: payload.margins.left,
      contentTopInset: payload.margins.top,
      fontSize: 17,
      fontColor: -16777216,
      corner: payload.corner,
      textWrap: payload.textWrap,
      enableCaption: payload.enableCaption,
      paper: cloneOriginalPaper(payload.paper),
      resizesWidthToFitText: payload.resizesWidthToFitText,
      positionLocked: payload.positionLocked,
    };
    text.bounds = textBlockWorldBounds(text);
    return text;
  }

  private buildImageBlock(operation: StoredSyncedOperation,
    payload: OriginalCreateBlockPayload): ImageElement {
    const asset: OriginalImageAsset = payload.image as OriginalImageAsset;
    const rotation: number = payload.rotation === null ? 0 : payload.rotation;
    const scaleX: number = payload.scaleX === null ? 1 : payload.scaleX;
    const scaleY: number = payload.scaleY === null ? 1 : payload.scaleY;
    const image: ImageElement = {
      id: encodeOperationId(operation),
      type: ElementType.IMAGE,
      transform: blockTransform(payload.originX, payload.originY, rotation, scaleX, scaleY),
      bounds: { left: 0, top: 0, right: 0, bottom: 0 },
      assetHash: originalAssetHashKey(asset.assetHash.bits),
      assetHashBits: asset.assetHash.bits.slice(),
      fileName: asset.fileName,
      mimeType: asset.mimeType,
      fileSize: asset.fileSize,
      intrinsicWidth: asset.width,
      intrinsicHeight: asset.height,
      cropRect: payload.cropRect === null ? null : {
        left: payload.cropRect.x,
        top: payload.cropRect.y,
        right: payload.cropRect.x + payload.cropRect.width,
        bottom: payload.cropRect.y + payload.cropRect.height,
      },
      blockWidth: payload.width,
      blockHeight: payload.height,
      rotationRadians: rotation,
      corner: payload.corner,
      textWrap: payload.textWrap,
      enableCaption: payload.enableCaption,
      webUrl: payload.webUrl,
      imageFlippedHorizontally: payload.imageFlippedHorizontally,
      imageFlippedVertically: payload.imageFlippedVertically,
      positionLocked: payload.positionLocked,
    };
    image.bounds = imageBlockWorldBounds(image);
    return image;
  }

  private buildMathBlock(operation: StoredSyncedOperation,
    payload: OriginalCreateBlockPayload): MathElement {
    const rotation: number = payload.rotation === null ? 0 : payload.rotation;
    const scaleX: number = payload.scaleX === null ? 1 : payload.scaleX;
    const scaleY: number = payload.scaleY === null ? 1 : payload.scaleY;
    const math: MathElement = {
      id: encodeOperationId(operation),
      type: ElementType.MATH,
      transform: blockTransform(payload.originX, payload.originY, rotation, scaleX, scaleY),
      bounds: { left: 0, top: 0, right: 0, bottom: 0 },
      latex: payload.mathLatex as string,
      color: payload.mathColor as number,
      blockWidth: payload.width,
      blockHeight: payload.height,
      rotationRadians: rotation,
      corner: payload.corner,
      textWrap: payload.textWrap,
      enableCaption: payload.enableCaption,
      positionLocked: payload.positionLocked,
    };
    math.bounds = mathBlockWorldBounds(math);
    return math;
  }

  private async mergeImageAssetReference(store: relationalStore.RdbStore, noteId: string,
    asset: OriginalImageAsset): Promise<string | null> {
    const storageHash: string = originalAssetStorageHash(asset.assetHash.bits);
    const legacyHash: string = originalAssetHashKey(asset.assetHash.bits);
    const rows: StoredAssetRow[] = await this.readAssetRows(store, storageHash, legacyHash);
    for (const row of rows) {
      if (row.fileSize !== asset.fileSize ||
        row.mimeType.toLowerCase() !== asset.mimeType.toLowerCase()) {
        return 'CREATE_BLOCK_IMAGE_ASSET_METADATA_CONFLICT';
      }
    }
    if (rows.length === 0) {
      await store.insert('note_asset', {
        'asset_hash': storageHash,
        'status': AssetStatus.PENDING,
        'note_ids': JSON.stringify([noteId]),
        'file_size': asset.fileSize,
        'mime_type': asset.mimeType,
        'local_path': null,
      });
      return null;
    }
    if (rows.length === 1) {
      const row: StoredAssetRow = rows[0];
      const predicates = new relationalStore.RdbPredicates('note_asset');
      predicates.equalTo('asset_hash', row.assetHash);
      const updated: number = await store.update({
        'note_ids': JSON.stringify(mergeNoteIds(row.noteIds, [noteId])),
      }, predicates);
      if (updated !== 1) {
        throw new Error('original image asset reference changed concurrently');
      }
      return null;
    }
    const canonical: StoredAssetRow = rows.find(
      (row: StoredAssetRow): boolean => row.assetHash === storageHash) as StoredAssetRow;
    const legacy: StoredAssetRow = rows.find(
      (row: StoredAssetRow): boolean => row.assetHash === legacyHash) as StoredAssetRow;
    if (canonical.localPath !== null && legacy.localPath !== null &&
      canonical.localPath !== legacy.localPath) {
      return 'CREATE_BLOCK_IMAGE_ASSET_PATH_CONFLICT';
    }
    const preferred: StoredAssetRow = preferredAssetRow(canonical, legacy);
    const mergedIds: string[] = mergeNoteIds(
      mergeNoteIds(canonical.noteIds, legacy.noteIds), [noteId]);
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.equalTo('asset_hash', storageHash);
    const updated: number = await store.update({
      'status': preferred.status,
      'note_ids': JSON.stringify(mergedIds),
      'file_size': canonical.fileSize,
      'mime_type': canonical.mimeType,
      'local_path': preferred.localPath,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original canonical image asset changed concurrently');
    }
    const legacyPredicates = new relationalStore.RdbPredicates('note_asset');
    legacyPredicates.equalTo('asset_hash', legacyHash);
    if (await store.delete(legacyPredicates) !== 1) {
      throw new Error('original legacy image asset changed concurrently');
    }
    return null;
  }

  private async readAssetRows(store: relationalStore.RdbStore,
    storageHash: string, legacyHash: string): Promise<StoredAssetRow[]> {
    const rows = storageHash === legacyHash ? await store.querySql(
      `SELECT asset_hash, status, note_ids, file_size, mime_type, local_path
       FROM note_asset WHERE asset_hash = ?`, [storageHash]) : await store.querySql(
      `SELECT asset_hash, status, note_ids, file_size, mime_type, local_path
       FROM note_asset WHERE asset_hash = ? OR asset_hash = ?`, [storageHash, legacyHash]);
    const result: StoredAssetRow[] = [];
    try {
      while (rows.goToNextRow()) {
        const localPathColumn: number = rows.getColumnIndex('local_path');
        const status: number = rows.getLong(rows.getColumnIndex('status'));
        if (status < AssetStatus.PENDING || status > AssetStatus.FAILED) {
          throw new Error('original image asset has an invalid status');
        }
        result.push({
          assetHash: rows.getString(rows.getColumnIndex('asset_hash')),
          status: status,
          noteIds: parseAssetNoteIds(rows.getString(rows.getColumnIndex('note_ids'))),
          fileSize: rows.getLong(rows.getColumnIndex('file_size')),
          mimeType: rows.getString(rows.getColumnIndex('mime_type')),
          localPath: rows.isColumnNull(localPathColumn) ? null : rows.getString(localPathColumn),
        });
      }
      return result;
    } finally {
      rows.close();
    }
  }

  private async readTargetPage(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, page: OriginalSequenceIdentity): Promise<StoredTargetPage | null> {
    const identity = await store.querySql(
      `SELECT page_id, visible FROM original_page_identity WHERE note_id = ?
       AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?`,
      [operation.noteId, page.timestamp, page.siteId, page.index]);
    let pageId: string | null = null;
    try {
      if (!identity.goToFirstRow() || identity.getLong(identity.getColumnIndex('visible')) !== 1) {
        return null;
      }
      const pageIdColumn: number = identity.getColumnIndex('page_id');
      pageId = identity.isColumnNull(pageIdColumn) ? null : identity.getString(pageIdColumn);
    } finally {
      identity.close();
    }
    if (pageId === null) {
      return null;
    }
    const liveRevision: number | null = await readSingleRevision(store,
      'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?',
      [operation.noteId, pageId]);
    const archivedRevision: number | null = await readSingleRevision(store,
      `SELECT content_revision FROM original_deleted_page WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [operation.noteId, page.timestamp, page.siteId, page.index]);
    if ((liveRevision === null) === (archivedRevision === null)) {
      return null;
    }
    return liveRevision !== null ? {
      pageId: pageId, table: 'page_element_snapshot', revision: liveRevision, archived: false,
    } : {
      pageId: pageId, table: 'original_deleted_page_element',
      revision: archivedRevision as number, archived: true,
    };
  }

  private async originalElementExists(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<boolean> {
    const rows = await store.querySql(
      `SELECT 1 FROM original_element_z_index WHERE note_id = ?
       AND element_timestamp = ? AND element_site_id = ? LIMIT 1`,
      [operation.noteId, operation.timestamp, operation.siteId]);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
  }

  private async originalCreateMatches(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, payload: OriginalCreateBlockPayload): Promise<boolean> {
    const kind: number = payload.blockType === OriginalBlockType.IMAGE ? PageElementKind.IMAGE :
      payload.blockType === OriginalBlockType.MATH ? PageElementKind.MATH : PageElementKind.TEXT;
    const image: OriginalImageAsset | null = payload.image;
    let baselineMatches: boolean = false;
    const rows = await store.querySql(
      `SELECT z.kind, state.* FROM original_element_z_index z
       JOIN original_block_state state ON state.note_id = z.note_id
        AND state.block_timestamp = z.element_timestamp
        AND state.block_site_id = z.element_site_id
       WHERE z.note_id = ? AND z.element_timestamp = ? AND z.element_site_id = ?`,
      [operation.noteId, operation.timestamp, operation.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return false;
      }
      baselineMatches = rows.getLong(rows.getColumnIndex('kind')) === kind &&
        rows.getLong(rows.getColumnIndex('block_type')) === payload.blockType &&
        rows.getLong(rows.getColumnIndex('create_page_timestamp')) === payload.page.timestamp &&
        rows.getLong(rows.getColumnIndex('create_page_site_id')) === payload.page.siteId &&
        rows.getLong(rows.getColumnIndex('create_page_index')) === payload.page.index &&
        rows.getDouble(rows.getColumnIndex('create_origin_x')) === payload.originX &&
        rows.getDouble(rows.getColumnIndex('create_origin_y')) === payload.originY &&
        readNullableDouble(rows, 'create_rotation') === payload.rotation &&
        readNullableDouble(rows, 'create_scale_x') === payload.scaleX &&
        readNullableDouble(rows, 'create_scale_y') === payload.scaleY &&
        rows.getDouble(rows.getColumnIndex('create_width')) === payload.width &&
        rows.getDouble(rows.getColumnIndex('create_height')) === payload.height &&
        rows.getLong(rows.getColumnIndex('create_corner')) === payload.corner &&
        rows.getLong(rows.getColumnIndex('create_text_wrap')) === payload.textWrap &&
        rows.getLong(rows.getColumnIndex('create_enable_caption')) ===
          (payload.enableCaption ? 1 : 0) &&
        rows.getLong(rows.getColumnIndex('create_position_locked')) ===
          (payload.positionLocked ? 1 : 0) &&
        rows.getLong(rows.getColumnIndex('create_resizes_width')) ===
          (payload.resizesWidthToFitText ? 1 : 0) &&
        readNullableString(rows, 'create_text_paper') ===
          (payload.paper === null ? null : JSON.stringify(payload.paper)) &&
        readNullableString(rows, 'create_math_latex') === payload.mathLatex &&
        readNullableLong(rows, 'create_math_color') === payload.mathColor &&
        readNullableString(rows, 'create_image_hash_bits') ===
          (image === null ? null : JSON.stringify(image.assetHash.bits)) &&
        readNullableString(rows, 'create_image_file_name') ===
          (image === null ? null : image.fileName) &&
        readNullableString(rows, 'create_image_mime_type') ===
          (image === null ? null : image.mimeType) &&
        readNullableLong(rows, 'create_image_file_size') ===
          (image === null ? null : image.fileSize) &&
        readNullableDouble(rows, 'create_image_width') ===
          (image === null ? null : image.width) &&
        readNullableDouble(rows, 'create_image_height') ===
          (image === null ? null : image.height) &&
        readNullableDouble(rows, 'create_image_crop_x') ===
          (payload.cropRect === null ? null : payload.cropRect.x) &&
        readNullableDouble(rows, 'create_image_crop_y') ===
          (payload.cropRect === null ? null : payload.cropRect.y) &&
        readNullableDouble(rows, 'create_image_crop_width') ===
          (payload.cropRect === null ? null : payload.cropRect.width) &&
        readNullableDouble(rows, 'create_image_crop_height') ===
          (payload.cropRect === null ? null : payload.cropRect.height) &&
        readNullableString(rows, 'create_image_web_url') === payload.webUrl &&
        readNullableLong(rows, 'create_image_flipped_horizontally') ===
          (image === null ? null : payload.imageFlippedHorizontally ? 1 : 0) &&
        readNullableLong(rows, 'create_image_flipped_vertically') ===
          (image === null ? null : payload.imageFlippedVertically ? 1 : 0) &&
        rows.getDouble(rows.getColumnIndex('create_margin_top')) === payload.margins.top &&
        rows.getDouble(rows.getColumnIndex('create_margin_bottom')) === payload.margins.bottom &&
        rows.getDouble(rows.getColumnIndex('create_margin_left')) === payload.margins.left &&
        rows.getDouble(rows.getColumnIndex('create_margin_right')) === payload.margins.right &&
        rows.getString(rows.getColumnIndex('create_z_index')) === payload.zIndex;
    } finally {
      rows.close();
    }
    if (!baselineMatches || !await this.originalMaterializedElementExists(
      store, operation, kind)) {
      return false;
    }
    return image === null || await this.imageAssetReferenceMatches(
      store, operation.noteId, image);
  }

  private async originalMaterializedElementExists(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, kind: number): Promise<boolean> {
    const elementId: string = encodeOperationId(operation);
    const rows = await store.querySql(
      `SELECT
        (SELECT COUNT(*) FROM page_element_snapshot
          WHERE note_id = ? AND element_id = ? AND kind = ?) +
        (SELECT COUNT(*) FROM original_deleted_page_element
          WHERE note_id = ? AND element_id = ? AND kind = ?) +
        (SELECT COUNT(*) FROM original_deleted_entity
          WHERE note_id = ? AND element_id = ? AND kind = ?) AS value`,
      [operation.noteId, elementId, kind, operation.noteId, elementId, kind,
        operation.noteId, elementId, kind]);
    try {
      return rows.goToFirstRow() && rows.getLong(rows.getColumnIndex('value')) === 1;
    } finally {
      rows.close();
    }
  }

  private async imageAssetReferenceMatches(store: relationalStore.RdbStore, noteId: string,
    asset: OriginalImageAsset): Promise<boolean> {
    const rows: StoredAssetRow[] = await this.readAssetRows(
      store, originalAssetStorageHash(asset.assetHash.bits), originalAssetHashKey(asset.assetHash.bits));
    return rows.length === 1 && rows[0].fileSize === asset.fileSize &&
      rows[0].mimeType.toLowerCase() === asset.mimeType.toLowerCase() &&
      rows[0].noteIds.indexOf(noteId) >= 0;
  }

  private async readCompleteOriginalOrder(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity, target: StoredTargetPage): Promise<StoredZIndexRow[] | null> {
    const tracked = await store.querySql(
      `SELECT element_timestamp, element_site_id, kind, z_index
       FROM original_element_z_index WHERE note_id = ? AND page_timestamp = ?
       AND page_site_id = ? AND page_index = ? AND visible = 1`,
      [noteId, page.timestamp, page.siteId, page.index]);
    const trackedRows: StoredZIndexRow[] = [];
    const trackedKeys: Set<string> = new Set<string>();
    try {
      while (tracked.goToNextRow()) {
        const timestamp: number = tracked.getLong(tracked.getColumnIndex('element_timestamp'));
        const siteId: number = tracked.getLong(tracked.getColumnIndex('element_site_id'));
        const kind: number = tracked.getLong(tracked.getColumnIndex('kind'));
        const elementId: string = encodeOperationId({ timestamp: timestamp, siteId: siteId });
        trackedRows.push({ elementId: elementId, kind: kind, timestamp: timestamp,
          siteId: siteId, zIndex: tracked.getString(tracked.getColumnIndex('z_index')) });
        trackedKeys.add(`${kind}:${elementId}`);
      }
    } finally {
      tracked.close();
    }
    const existing = target.archived ? await store.querySql(
      `SELECT element_id, kind FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]) : await store.querySql(
      'SELECT element_id, kind FROM page_element_snapshot WHERE note_id = ? AND page_id = ?',
      [noteId, target.pageId]);
    let count: number = 0;
    try {
      while (existing.goToNextRow()) {
        const key: string = `${existing.getLong(existing.getColumnIndex('kind'))}:` +
          existing.getString(existing.getColumnIndex('element_id'));
        if (!trackedKeys.has(key)) {
          return null;
        }
        count++;
      }
    } finally {
      existing.close();
    }
    return count === trackedRows.length ? trackedRows : null;
  }

  private async materializeOrder(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity, target: StoredTargetPage, rows: StoredZIndexRow[],
    element: TextBlockElement | ImageElement | MathElement, kind: PageElementKind,
    revision: number): Promise<void> {
    for (let index: number = 0; index < rows.length; index++) {
      const row: StoredZIndexRow = rows[index];
      if (row.elementId === element.id && row.kind === kind) {
        const persisted: PersistedElement = {
          kind: kind === PageElementKind.IMAGE ? 'image' :
            kind === PageElementKind.MATH ? 'math' : 'text', data: element,
        };
        const values: relationalStore.ValuesBucket = {
          'note_id': noteId, 'element_id': element.id, 'kind': kind,
          'payload': encodePersistedElement(persisted), 'revision': revision,
          'element_order': index,
        };
        if (target.archived) {
          values['page_timestamp'] = page.timestamp;
          values['page_site_id'] = page.siteId;
          values['page_index'] = page.index;
        } else {
          values['page_id'] = target.pageId;
        }
        await store.insert(target.table, values);
      } else {
        const predicates = new relationalStore.RdbPredicates(target.table);
        predicates.equalTo('note_id', noteId);
        if (target.archived) {
          predicates.equalTo('page_timestamp', page.timestamp);
          predicates.equalTo('page_site_id', page.siteId);
          predicates.equalTo('page_index', page.index);
        } else {
          predicates.equalTo('page_id', target.pageId);
        }
        predicates.equalTo('element_id', row.elementId);
        predicates.equalTo('kind', row.kind);
        const updated: number = await store.update({ 'element_order': index }, predicates);
        if (updated !== 1) {
          throw new Error('original element order materialization lost an element');
        }
      }
    }
    if (target.archived) {
      const predicates = new relationalStore.RdbPredicates('original_deleted_page');
      predicates.equalTo('note_id', noteId);
      predicates.equalTo('page_timestamp', page.timestamp);
      predicates.equalTo('page_site_id', page.siteId);
      predicates.equalTo('page_index', page.index);
      predicates.equalTo('content_revision', target.revision);
      const updated: number = await store.update({ 'content_revision': revision,
        'indexed_revision': null }, predicates);
      if (updated !== 1) {
        throw new Error('original archived page revision changed concurrently');
      }
      if (kind === PageElementKind.TEXT) {
        await store.executeSql(
          `DELETE FROM original_deleted_page_search WHERE note_id = ? AND page_timestamp = ?
           AND page_site_id = ? AND page_index = ? AND type = ?`,
          [noteId, page.timestamp, page.siteId, page.index, SearchItemType.TEXT_BLOCK]);
      }
    } else {
      const predicates = new relationalStore.RdbPredicates('page_info');
      predicates.equalTo('note_id', noteId);
      predicates.equalTo('page_id', target.pageId);
      predicates.equalTo('content_revision', target.revision);
      const updated: number = await store.update({ 'content_revision': revision }, predicates);
      if (updated !== 1) {
        throw new Error('original live page revision changed concurrently');
      }
      await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
      if (kind === PageElementKind.TEXT) {
        await store.executeSql(
          'DELETE FROM search_item WHERE note_id = ? AND page_id = ? AND type = ?',
          [noteId, target.pageId, SearchItemType.TEXT_BLOCK]);
      }
    }
  }
}

function rgbaBytesToArgb(bytes: Uint8Array): number {
  return ((bytes[3] << 24) | (bytes[0] << 16) | (bytes[1] << 8) | bytes[2]) | 0;
}

function preferredAssetRow(canonical: StoredAssetRow, legacy: StoredAssetRow): StoredAssetRow {
  if (canonical.localPath !== null) {
    return canonical;
  }
  if (legacy.localPath !== null) {
    return legacy;
  }
  const canonicalUnavailable: boolean = canonical.status === AssetStatus.PENDING ||
    canonical.status === AssetStatus.FAILED;
  const legacyAvailable: boolean = legacy.status !== AssetStatus.PENDING &&
    legacy.status !== AssetStatus.FAILED;
  return canonicalUnavailable && legacyAvailable ? legacy : canonical;
}

function decodeOriginalImageAsset(table: OriginalFlatBufferTableReader): OriginalImageAsset {
  const metadata: OriginalFlatBufferTableReader | null = table.readTable(0);
  const size: Uint8Array | null = table.readInlineBytes(1, 8);
  if (metadata === null || size === null) {
    throw new Error('original image asset is missing metadata or size');
  }
  const hash: Uint8Array | null = metadata.readInlineBytes(0, 64);
  const fileName: string | null = metadata.readUtf8String(
    1, true, MAX_ORIGINAL_ASSET_FILE_NAME_BYTES);
  const mimeType: string | null = metadata.readUtf8String(
    2, true, MAX_ORIGINAL_ASSET_MIME_TYPE_BYTES);
  const fileSize: number = metadata.readUint32(3, 0);
  if (hash === null || fileName === null || fileName.length === 0 ||
    mimeType === null || mimeType.length === 0 || fileSize === 0) {
    throw new Error('original image asset metadata is invalid');
  }
  const width: number = readOriginalInlineFloat32(size, 0);
  const height: number = readOriginalInlineFloat32(size, 4);
  if (!validSize(width, height)) {
    throw new Error('original image asset size is invalid');
  }
  const bits: string[] = [];
  for (let index: number = 0; index < 8; index++) {
    bits.push(readOriginalInlineUint64Decimal(hash, index * 8));
  }
  return {
    assetHash: { bits: bits }, fileName: fileName, mimeType: mimeType,
    fileSize: fileSize, width: width, height: height,
  };
}

function normalizeOriginalEnum(value: number, maximum: number): number {
  return value >= 0 && value <= maximum ? value : 0;
}

function validMargins(margins: OriginalBlockMargins): boolean {
  return Number.isFinite(margins.top) && margins.top >= 0 &&
    Number.isFinite(margins.bottom) && margins.bottom >= 0 &&
    Number.isFinite(margins.left) && margins.left >= 0 &&
    Number.isFinite(margins.right) && margins.right >= 0;
}

function validSize(width: number, height: number): boolean {
  return Number.isFinite(width) && width >= 0 && Number.isFinite(height) && height >= 0;
}

function validRect(rect: OriginalBlockRect): boolean {
  return Number.isFinite(rect.x) && Number.isFinite(rect.y) && validSize(rect.width, rect.height);
}

function blockTransform(originX: number, originY: number, rotation: number,
  scaleX: number, scaleY: number): TransformMatrix {
  const cosine: number = Math.cos(rotation);
  const sine: number = Math.sin(rotation);
  return [cosine * scaleX, -sine * scaleY, originX,
    sine * scaleX, cosine * scaleY, originY, 0, 0, 1];
}

function compareStoredZIndexRows(left: StoredZIndexRow, right: StoredZIndexRow): number {
  let compared: number = compareUnsignedLongDecimal(left.zIndex, right.zIndex);
  if (compared !== 0) {
    return compared;
  }
  compared = left.timestamp === right.timestamp ? 0 : left.timestamp < right.timestamp ? -1 : 1;
  if (compared !== 0) {
    return compared;
  }
  return left.siteId === right.siteId ? 0 : left.siteId < right.siteId ? -1 : 1;
}

function readNullableLong(rows: relationalStore.ResultSet, columnName: string): number | null {
  const column: number = rows.getColumnIndex(columnName);
  return rows.isColumnNull(column) ? null : rows.getLong(column);
}

function readNullableDouble(rows: relationalStore.ResultSet, columnName: string): number | null {
  const column: number = rows.getColumnIndex(columnName);
  return rows.isColumnNull(column) ? null : rows.getDouble(column);
}

function readNullableString(rows: relationalStore.ResultSet, columnName: string): string | null {
  const column: number = rows.getColumnIndex(columnName);
  return rows.isColumnNull(column) ? null : rows.getString(column);
}

async function readSingleRevision(store: relationalStore.RdbStore, sql: string,
  args: relationalStore.ValueType[]): Promise<number | null> {
  const rows = await store.querySql(sql, args);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    const revision: number = rows.getLong(rows.getColumnIndex('content_revision'));
    if (!Number.isSafeInteger(revision) || revision < 0) {
      throw new Error('original target page has an invalid revision');
    }
    return revision;
  } finally {
    rows.close();
  }
}
