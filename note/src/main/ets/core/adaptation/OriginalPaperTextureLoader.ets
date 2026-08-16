import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { originalLegacyPaperResourceName } from '../model/OriginalPaperColor';

export const ORIGINAL_LEGACY_PAPER_TEXTURE_SIZE: number = 1024;

export interface LoadedOriginalPaperTexture {
  legacyPaperIndex: number;
  bitmap: ImageBitmap;
  pixelMap: image.PixelMap | null;
}

export class OriginalPaperTextureLoader {
  async load(context: common.UIAbilityContext,
    legacyPaperIndex: number): Promise<LoadedOriginalPaperTexture> {
    const resourceName: string | null = originalLegacyPaperResourceName(legacyPaperIndex);
    if (resourceName === null) {
      throw new Error(`Unsupported original legacy paper index: ${legacyPaperIndex}`);
    }
    let source: image.ImageSource | null = null;
    let pixelMap: image.PixelMap | null = null;
    try {
      const bytes: Uint8Array = await context.resourceManager.getRawFileContent(resourceName);
      const buffer: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset,
        bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
      source = image.createImageSource(buffer);
      pixelMap = await source.createPixelMap({
        editable: false,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      });
      const info: image.ImageInfo = await pixelMap.getImageInfo();
      if (info.size.width !== ORIGINAL_LEGACY_PAPER_TEXTURE_SIZE ||
        info.size.height !== ORIGINAL_LEGACY_PAPER_TEXTURE_SIZE) {
        throw new Error(`Unexpected legacy paper texture: ${info.size.width}x${info.size.height}`);
      }
      const loaded: LoadedOriginalPaperTexture = {
        legacyPaperIndex: legacyPaperIndex,
        bitmap: new ImageBitmap(pixelMap),
        pixelMap: pixelMap,
      };
      pixelMap = null;
      return loaded;
    } finally {
      if (pixelMap !== null) {
        try {
          await pixelMap.release();
        } catch (error) {
          console.warn(`Legacy paper PixelMap cleanup failed: ${JSON.stringify(error)}`);
        }
      }
      if (source !== null) {
        try {
          await source.release();
        } catch (error) {
          console.warn(`Legacy paper ImageSource cleanup failed: ${JSON.stringify(error)}`);
        }
      }
    }
  }

  release(loaded: LoadedOriginalPaperTexture): void {
    loaded.bitmap.close();
    if (loaded.pixelMap !== null) {
      loaded.pixelMap.release().catch((error: Object): void => {
        console.warn(`Legacy paper PixelMap release failed: ${JSON.stringify(error)}`);
      });
      loaded.pixelMap = null;
    }
  }
}
