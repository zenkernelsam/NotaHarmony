import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { applyOriginalPencilAlphaCurve, ORIGINAL_PENCIL_TEXTURE_SIZE } from './PencilSplatMath';

export interface LoadedPencilTexture {
  bitmap: ImageBitmap;
  pixelMap: image.PixelMap;
}

export async function loadOriginalPencilTexture(context: common.UIAbilityContext): Promise<LoadedPencilTexture> {
  let source: image.ImageSource | null = null;
  let pixelMap: image.PixelMap | null = null;
  try {
    const bytes: Uint8Array = await context.resourceManager.getRawFileContent('ui_renderer__pencil_splat.png');
    const buffer: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset,
      bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
    source = image.createImageSource(buffer);
    pixelMap = await source.createPixelMap({
      editable: true,
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
    });
    const info: image.ImageInfo = await pixelMap.getImageInfo();
    if (info.size.width !== ORIGINAL_PENCIL_TEXTURE_SIZE ||
      info.size.height !== ORIGINAL_PENCIL_TEXTURE_SIZE ||
      info.pixelFormat !== image.PixelMapFormat.RGBA_8888) {
      throw new Error(`Unexpected pencil texture: ${info.size.width}x${info.size.height}, format=${info.pixelFormat}`);
    }
    const pixelBuffer: ArrayBuffer = new ArrayBuffer(pixelMap.getPixelBytesNumber());
    await pixelMap.readPixelsToBuffer(pixelBuffer);
    applyOriginalPencilAlphaCurve(new Uint8Array(pixelBuffer), info.size.width,
      info.size.height, pixelMap.getBytesNumberPerRow());
    await pixelMap.writeBufferToPixels(pixelBuffer);
    const result: LoadedPencilTexture = { bitmap: new ImageBitmap(pixelMap), pixelMap: pixelMap };
    pixelMap = null;
    return result;
  } finally {
    if (pixelMap !== null) {
      try {
        await pixelMap.release();
      } catch (e) {
        console.warn(`Pencil PixelMap cleanup failed: ${JSON.stringify(e)}`);
      }
    }
    if (source !== null) {
      try {
        await source.release();
      } catch (e) {
        console.warn(`Pencil ImageSource cleanup failed: ${JSON.stringify(e)}`);
      }
    }
  }
}
