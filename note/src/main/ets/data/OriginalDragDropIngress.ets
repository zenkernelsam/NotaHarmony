import { image } from '@kit.ImageKit';
import { unifiedDataChannel } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
import { normalizeOriginalImageBytes } from './OriginalImageNormalizer';
import {
  normalizeOriginalPixelMap, NormalizedOriginalClipboardImage,
} from './OriginalClipboardImageIngress';
import {
  importOriginalPhotos, isValidOriginalPhotoUri, OriginalPhotoIngressItem,
} from './OriginalPhotoIngress';

// 原版 e0f.P0：拖放落地时遍历 ClipData 全部 item，收集 getUri() 非空的
// 条目交给插入回调（wx4.invoke(arrayList, mp5(落点))），不解码即拒收。
// Harmony UDMF 等价面：general.file-uri / general.image 记录给出 URI；
// general.pixelmap 记录直接给出位图（等价原版 URI 指向位图解码结果）。
export interface OriginalDroppedImagePayload {
  uris: string[];
  pixelMaps: image.PixelMap[];
}

const UDT_FILE_URI: string = 'general.file-uri';
const UDT_IMAGE: string = 'general.image';
const UDT_PIXELMAP: string = 'general.pixelmap';

export function extractOriginalDroppedImagePayload(data: unifiedDataChannel.UnifiedData):
  OriginalDroppedImagePayload {
  const payload: OriginalDroppedImagePayload = { uris: [], pixelMaps: [] };
  if (data === null || data === undefined) {
    return payload;
  }
  let records: unifiedDataChannel.UnifiedRecord[];
  try {
    records = data.getRecords();
  } catch (_error) {
    return payload;
  }
  for (const record of records) {
    if (record === null || record === undefined) {
      continue;
    }
    let recordType: string;
    try {
      recordType = record.getType();
    } catch (_error) {
      continue;
    }
    if (recordType !== UDT_FILE_URI && recordType !== UDT_IMAGE &&
      recordType !== UDT_PIXELMAP) {
      continue;
    }
    let value: unifiedDataChannel.ValueType;
    try {
      value = record.getValue();
    } catch (_error) {
      continue;
    }
    if (typeof value === 'string') {
      if (value.length > 0) {
        payload.uris.push(value);
      }
      continue;
    }
    if (typeof value === 'object' && value !== null) {
      const uriValue: unifiedDataChannel.ValueType =
        (value as Record<string, unifiedDataChannel.ValueType>)['uri'];
      if (typeof uriValue === 'string' && uriValue.length > 0) {
        payload.uris.push(uriValue);
        continue;
      }
      const maybePixelMap: image.PixelMap = value as image.PixelMap;
      if (typeof maybePixelMap.getImageInfo === 'function') {
        payload.pixelMaps.push(maybePixelMap);
      }
    }
  }
  return payload;
}

export function isOriginalDroppedImagePayloadEmpty(
  payload: OriginalDroppedImagePayload): boolean {
  return payload.uris.length === 0 && payload.pixelMaps.length === 0;
}

// 原版收集全部 URI 后逐条读取解码——不以扩展名门禁拒收（picker 的
// isValidOriginalPhotoUri 是选择器约束，拖放侧由 ImageSource 解码失败兜底）。
// 无扩展名 URI 仍先尝试解码；解码失败的条目被跳过而非整体中止。
export async function importOriginalDroppedImages(
  payload: OriginalDroppedImagePayload, cacheDirectory: string):
  Promise<OriginalPhotoIngressItem[]> {
  const items: OriginalPhotoIngressItem[] = [];
  const extensionUris: string[] = [];
  const extensionlessUris: string[] = [];
  for (const uri of payload.uris) {
    if (isValidOriginalPhotoUri(uri)) {
      extensionUris.push(uri);
    } else {
      extensionlessUris.push(uri);
    }
  }
  if (extensionUris.length > 0) {
    const imported: OriginalPhotoIngressItem[] =
      await importOriginalPhotos(extensionUris, cacheDirectory);
    for (const item of imported) {
      items.push(item);
    }
  }
  for (const uri of extensionlessUris) {
    const item: OriginalPhotoIngressItem | null =
      await importExtensionlessDroppedImage(uri, items.length);
    if (item !== null) {
      items.push(item);
    }
  }
  for (const pixelMap of payload.pixelMaps) {
    const normalized: NormalizedOriginalClipboardImage =
      await normalizeOriginalPixelMap(pixelMap);
    items.push({
      bytes: normalized.bytes,
      fileName: `dropped-${items.length}.webp`,
      mimeType: 'image/webp',
      rewroteBytes: true,
      encodedWidth: normalized.width,
      encodedHeight: normalized.height,
      orientedWidth: normalized.width,
      orientedHeight: normalized.height,
    });
  }
  return items;
}

async function importExtensionlessDroppedImage(uri: string, index: number):
  Promise<OriginalPhotoIngressItem | null> {
  let file: fileIo.File | null = null;
  try {
    file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    const stat: fileIo.Stat = fileIo.statSync(file.fd);
    if (!Number.isSafeInteger(stat.size) || stat.size <= 0 || stat.size > 104857600) {
      return null;
    }
    const bytes: Uint8Array = new Uint8Array(stat.size);
    let total: number = 0;
    while (total < stat.size) {
      const chunk: ArrayBuffer = new ArrayBuffer(Math.min(1048576, stat.size - total));
      const read: number = fileIo.readSync(file.fd, chunk);
      if (read <= 0) {
        return null;
      }
      bytes.set(new Uint8Array(chunk, 0, read), total);
      total += read;
    }
    const normalized = await normalizeOriginalImageBytes(bytes);
    const extension: string = normalized.rewroteBytes ? 'webp' : 'img';
    return {
      bytes: normalized.bytes,
      fileName: `dropped-${index}.${extension}`,
      mimeType: normalized.mimeType,
      rewroteBytes: normalized.rewroteBytes,
      encodedWidth: normalized.encodedWidth,
      encodedHeight: normalized.encodedHeight,
      orientedWidth: normalized.orientedWidth,
      orientedHeight: normalized.orientedHeight,
    };
  } catch (_error) {
    return null;
  } finally {
    if (file !== null) {
      fileIo.closeSync(file);
    }
  }
}
