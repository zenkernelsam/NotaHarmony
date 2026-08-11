import { OriginalAssetMetadata } from '../core/model/NoteTypes';
import {
  OriginalFlatBufferTableReader, readOriginalInlineUint64Decimal,
} from './OriginalSyncedOperationFlatBuffer';

const MAX_ORIGINAL_ASSET_FILE_NAME_BYTES: number = 65536;
const MAX_ORIGINAL_ASSET_MIME_TYPE_BYTES: number = 4096;

export function decodeOriginalAssetMetadata(table: OriginalFlatBufferTableReader): OriginalAssetMetadata {
  const hash: Uint8Array | null = table.readInlineBytes(0, 64);
  const fileName: string | null = table.readUtf8String(
    1, true, MAX_ORIGINAL_ASSET_FILE_NAME_BYTES);
  const mimeType: string | null = table.readUtf8String(
    2, true, MAX_ORIGINAL_ASSET_MIME_TYPE_BYTES);
  const fileSize: number = table.readUint32(3, 0);
  if (hash === null || fileName === null || fileName.length === 0 ||
    mimeType === null || mimeType.length === 0 || fileSize === 0) {
    throw new Error('original asset metadata is invalid');
  }
  const bits: string[] = [];
  for (let index: number = 0; index < 8; index++) {
    bits.push(readOriginalInlineUint64Decimal(hash, index * 8));
  }
  return {
    assetHashBits: bits,
    fileName: fileName,
    mimeType: mimeType,
    fileSize: fileSize,
  };
}
