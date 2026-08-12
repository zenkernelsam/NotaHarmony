import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { initialize as initializeNative, MathMeasureResult, measure as measureNative,
  MathRenderResult, render as renderNative } from 'libnota_math.so';

const ROOT_NAME: string = 'glmath';
const MAX_RESOURCE_FILES: number = 128;
const MAX_RESOURCE_BYTES: number = 16 * 1024 * 1024;

export interface OriginalMathBitmap {
  bitmap: ImageBitmap;
  pixelMap: image.PixelMap;
  width: number;
  height: number;
}

class OriginalMathEngine {
  private ready: boolean = false;
  private initializing: Promise<boolean> | null = null;
  private root: string = '';

  async initialize(context: common.UIAbilityContext): Promise<boolean> {
    if (this.ready) return true;
    if (this.initializing !== null) return this.initializing;
    this.initializing = this.prepare(context).finally(() => { this.initializing = null; });
    return this.initializing;
  }

  isReady(): boolean { return this.ready; }

  measure(latex: string, width: number, fontSize: number): MathMeasureResult {
    if (!this.ready) return { valid: false, error: 'math engine is not initialized' };
    return measureNative(latex, width, fontSize);
  }

  render(latex: string, width: number, height: number, fontSize: number,
    argbColor: number, pixelScale: number): OriginalMathBitmap | null {
    if (!this.ready) return null;
    const result: MathRenderResult = renderNative(latex, width, height, fontSize, argbColor, pixelScale);
    if (!result.valid || result.pixels === undefined || result.width === undefined || result.height === undefined) {
      return null;
    }
    const pixelMap: image.PixelMap = image.createPixelMapSync(result.pixels, {
      editable: false,
      srcPixelFormat: image.PixelMapFormat.RGBA_8888,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      size: { width: result.width, height: result.height },
    });
    return { bitmap: new ImageBitmap(pixelMap), pixelMap, width: result.width, height: result.height };
  }

  private async prepare(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const root: string = `${context.filesDir}/${ROOT_NAME}`;
      fileIo.mkdirSync(root, true);
      const files: string[] = context.resourceManager.getRawFileListSync(ROOT_NAME);
      if (files.length === 0 || files.length > MAX_RESOURCE_FILES) throw new Error('glmath resources are missing');
      let totalBytes: number = 0;
      for (const relative of files) {
        if (relative.length === 0 || relative.includes('..') || relative.startsWith('/')) continue;
        const bytes: Uint8Array = context.resourceManager.getRawFileContentSync(`${ROOT_NAME}/${relative}`);
        totalBytes += bytes.byteLength;
        if (totalBytes > MAX_RESOURCE_BYTES) throw new Error('glmath resources exceed budget');
        const output: string = `${root}/${relative}`;
        const slash: number = output.lastIndexOf('/');
        if (slash > 0) fileIo.mkdirSync(output.substring(0, slash), true);
        const file: fileIo.File = fileIo.openSync(output,
          fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
        try {
          fileIo.writeSync(file.fd, bytes.buffer.slice(bytes.byteOffset,
            bytes.byteOffset + bytes.byteLength) as ArrayBuffer);
          fileIo.fsyncSync(file.fd);
        } finally {
          fileIo.closeSync(file.fd);
        }
      }
      this.ready = initializeNative(root);
      this.root = this.ready ? root : '';
      return this.ready;
    } catch (error) {
      this.ready = false;
      this.root = '';
      console.error(`Original math engine initialization failed: ${JSON.stringify(error)}`);
      return false;
    }
  }
}

export const originalMathEngine: OriginalMathEngine = new OriginalMathEngine();
