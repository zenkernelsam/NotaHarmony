import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { ImageElement } from '../model/ElementTypes';
import { originalAssetLookupKeys } from '../model/ImageBlockGeometry';
import { AssetStatus, NoteAsset } from '../model/AssetTypes';
import { AssetRepositoryImpl } from '../../data/AssetRepositoryImpl';
import { DatabaseManager } from '../../data/DatabaseManager';

const ORIGINAL_MAX_IMAGE_EDGE: number = 3000;

export enum ImageAssetLoadState {
  MISSING = 0,
  PENDING = 1,
  READY = 2,
  FAILED = 3,
  ANIMATED_UNSUPPORTED = 4,
}

export interface LoadedImageAsset {
  state: ImageAssetLoadState;
  lookupKey: string;
  bitmap: ImageBitmap | null;
  pixelMap: image.PixelMap | null;
  error: string | null;
}

export class ImageAssetLoader {
  private repository: AssetRepositoryImpl;

  constructor(database: DatabaseManager) {
    this.repository = new AssetRepositoryImpl(database);
  }

  async load(element: ImageElement): Promise<LoadedImageAsset> {
    const keys: string[] = originalAssetLookupKeys(element);
    let asset: NoteAsset | null = null;
    let lookupKey: string = keys[0];
    for (const key of keys) {
      const candidate: NoteAsset | null = await this.repository.getAsset(key);
      if (candidate !== null) {
        asset = candidate;
        lookupKey = key;
        break;
      }
    }
    if (asset === null) {
      return this.empty(ImageAssetLoadState.MISSING, lookupKey, 'asset metadata is absent');
    }
    if (element.mimeType.toLowerCase() === 'image/gif' || asset.mimeType.toLowerCase() === 'image/gif') {
      return this.empty(ImageAssetLoadState.ANIMATED_UNSUPPORTED, lookupKey,
        'animated GIF requires the original dedicated image view');
    }
    if (asset.status === AssetStatus.FAILED) {
      return this.empty(ImageAssetLoadState.FAILED, lookupKey, 'asset is marked failed');
    }
    if (asset.localPath === null || asset.localPath.length === 0) {
      return this.empty(ImageAssetLoadState.PENDING, lookupKey, 'asset has no local file yet');
    }
    return await this.decodeLocalFile(asset, element, lookupKey);
  }

  release(loaded: LoadedImageAsset): void {
    if (loaded.bitmap !== null) {
      loaded.bitmap.close();
      loaded.bitmap = null;
    }
    if (loaded.pixelMap !== null) {
      loaded.pixelMap.release().catch((error: Object) => {
        console.warn(`Image PixelMap release failed: ${JSON.stringify(error)}`);
      });
      loaded.pixelMap = null;
    }
  }

  private async decodeLocalFile(asset: NoteAsset, element: ImageElement,
    lookupKey: string): Promise<LoadedImageAsset> {
    let source: image.ImageSource | null = null;
    let pixelMap: image.PixelMap | null = null;
    let openedFile: fileIo.File | null = null;
    try {
      const path: string = asset.localPath as string;
      const stat = fileIo.statSync(path);
      if (stat.size <= 0 || (asset.fileSize > 0 && stat.size !== asset.fileSize) ||
        (element.fileSize > 0 && stat.size !== element.fileSize)) {
        return this.empty(ImageAssetLoadState.FAILED, lookupKey, 'asset file size does not match metadata');
      }
      openedFile = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      source = image.createImageSource(openedFile.fd);
      const info: image.ImageInfo = await source.getImageInfo();
      const maximum: number = Math.max(info.size.width, info.size.height);
      const options: image.DecodingOptions = { editable: false };
      if (maximum > ORIGINAL_MAX_IMAGE_EDGE) {
        const ratio: number = ORIGINAL_MAX_IMAGE_EDGE / maximum;
        options.desiredSize = {
          width: Math.max(1, Math.round(info.size.width * ratio)),
          height: Math.max(1, Math.round(info.size.height * ratio)),
        };
      }
      pixelMap = await source.createPixelMap(options);
      const bitmap: ImageBitmap = new ImageBitmap(pixelMap);
      return { state: ImageAssetLoadState.READY, lookupKey: lookupKey,
        bitmap: bitmap, pixelMap: pixelMap, error: null };
    } catch (error) {
      if (pixelMap !== null) {
        try {
          await pixelMap.release();
        } catch (_releaseError) {
        }
      }
      return this.empty(ImageAssetLoadState.FAILED, lookupKey, JSON.stringify(error));
    } finally {
      if (source !== null) {
        try {
          await source.release();
        } catch (_releaseError) {
        }
      }
      if (openedFile !== null) {
        fileIo.closeSync(openedFile);
      }
    }
  }

  private empty(state: ImageAssetLoadState, lookupKey: string, error: string): LoadedImageAsset {
    return { state: state, lookupKey: lookupKey, bitmap: null, pixelMap: null, error: error };
  }
}
