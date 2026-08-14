import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { initialize as initializeNative, MathMeasureResult, measure as measureNative,
  MathRenderResult, render as renderNative } from 'libnota_math.so';
import { fitOriginalMathMeasuredSizeToBox, OriginalMathMeasuredSize,
  originalMathMeasurementFontSize } from '../core/model/OriginalMathInsertPlan';

const ROOT_NAME: string = 'glmath';
const RESOURCE_VERSION: string = 'v1';
const COMPLETE_MARKER: string = '.complete';
const MAX_RESOURCE_FILES: number = 128;
const MAX_RESOURCE_BYTES: number = 16 * 1024 * 1024;
const RESOURCE_WRITE_CHUNK_SIZE: number = 64 * 1024;

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

  fit(latex: string, width: number, height: number): OriginalMathMeasuredSize | null {
    if (!this.ready || latex.trim().length === 0) return null;
    const measurementFontSize: number | null = originalMathMeasurementFontSize(width, height);
    if (measurementFontSize === null) return null;
    const measured: MathMeasureResult = this.measure(latex, width, measurementFontSize);
    if (!measured.valid || measured.width === undefined || measured.height === undefined) {
      return null;
    }
    return fitOriginalMathMeasuredSizeToBox(width, height, measured.width, measured.height);
  }

  render(latex: string, width: number, height: number,
    argbColor: number, pixelScale: number): OriginalMathBitmap | null {
    if (!this.ready) return null;
    const fitted: OriginalMathMeasuredSize | null = this.fit(latex, width, height);
    if (fitted === null) return null;
    const result: MathRenderResult = renderNative(
      latex, width, height, fitted.fontSize, argbColor, pixelScale);
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
      const baseRoot: string = `${context.filesDir}/${ROOT_NAME}`;
      const root: string = `${baseRoot}/${RESOURCE_VERSION}`;
      const marker: string = `${root}/${COMPLETE_MARKER}`;
      if (!isRegularFile(marker)) {
        removeTree(baseRoot);
        fileIo.mkdirSync(root, true);
        try {
          extractResources(context, root);
          createCompletionMarker(marker);
        } catch (error) {
          try { removeTree(baseRoot); } catch (_cleanupError) { }
          throw new Error(`glmath resource extraction failed: ${JSON.stringify(error)}`);
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

function extractResources(context: common.UIAbilityContext, root: string): void {
  const files: string[] = context.resourceManager.getRawFileListSync(ROOT_NAME);
  if (files.length === 0 || files.length > MAX_RESOURCE_FILES) {
    throw new Error('glmath resources are missing');
  }
  let totalBytes: number = 0;
  for (const relative of files) {
    if (!isSafeRelativeResourcePath(relative)) {
      throw new Error(`glmath resource path is unsafe: ${relative}`);
    }
    const bytes: Uint8Array =
      context.resourceManager.getRawFileContentSync(`${ROOT_NAME}/${relative}`);
    totalBytes += bytes.byteLength;
    if (!Number.isSafeInteger(totalBytes) || totalBytes > MAX_RESOURCE_BYTES) {
      throw new Error('glmath resources exceed budget');
    }
    const output: string = `${root}/${relative}`;
    const slash: number = output.lastIndexOf('/');
    if (slash > 0) {
      fileIo.mkdirSync(output.substring(0, slash), true);
    }
    writeResourceFile(output, bytes);
  }
}

function writeResourceFile(path: string, bytes: Uint8Array): void {
  const file: fileIo.File = fileIo.openSync(path,
    fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  try {
    let total: number = 0;
    while (total < bytes.byteLength) {
      const requested: number = Math.min(RESOURCE_WRITE_CHUNK_SIZE, bytes.byteLength - total);
      const exact: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset + total,
        bytes.byteOffset + total + requested) as ArrayBuffer;
      const written: number = fileIo.writeSync(file.fd, exact);
      if (written <= 0 || written > requested) {
        throw new Error(`glmath resource write made invalid progress: ${total}/${bytes.byteLength}`);
      }
      total += written;
    }
    fileIo.fsyncSync(file.fd);
  } finally {
    fileIo.closeSync(file);
  }
  if (!isRegularFile(path) || fileIo.statSync(path).size !== bytes.byteLength) {
    throw new Error(`glmath resource write verification failed: ${path}`);
  }
}

function createCompletionMarker(path: string): void {
  const marker: fileIo.File = fileIo.openSync(path,
    fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  try {
    fileIo.fsyncSync(marker.fd);
  } finally {
    fileIo.closeSync(marker);
  }
  if (!isRegularFile(path) || fileIo.statSync(path).size !== 0) {
    throw new Error('glmath completion marker was not created');
  }
}

function isSafeRelativeResourcePath(relative: string): boolean {
  if (relative.length === 0 || relative.startsWith('/') || relative.indexOf('\\') >= 0) {
    return false;
  }
  const segments: string[] = relative.split('/');
  for (const segment of segments) {
    if (segment.length === 0 || segment === '.' || segment === '..') {
      return false;
    }
  }
  return true;
}

function isRegularFile(path: string): boolean {
  try {
    return fileIo.accessSync(path) && fileIo.lstatSync(path).isFile();
  } catch (_error) {
    return false;
  }
}

function removeTree(path: string): void {
  if (!fileIo.accessSync(path)) {
    return;
  }
  const stat = fileIo.lstatSync(path);
  if (stat.isSymbolicLink() || !stat.isDirectory()) {
    fileIo.unlinkSync(path);
    return;
  }
  const children: string[] = fileIo.listFileSync(path, { recursion: false });
  for (const child of children) {
    const candidate: string | null = directChildPath(path, child);
    if (candidate === null) {
      throw new Error(`glmath cleanup refused a non-child path: ${child}`);
    }
    removeTree(candidate);
  }
  fileIo.rmdirSync(path);
}

function directChildPath(directory: string, listed: string): string | null {
  const normalizedDirectory: string = normalizePath(directory);
  const normalizedListed: string = normalizePath(listed);
  let candidate: string;
  if (normalizedListed.startsWith(normalizedDirectory + '/')) {
    candidate = normalizedListed;
  } else if (normalizedListed.indexOf('/') < 0) {
    candidate = normalizedDirectory + '/' + normalizedListed;
  } else {
    return null;
  }
  const relative: string = candidate.substring(normalizedDirectory.length + 1);
  if (relative.length === 0 || relative.indexOf('/') >= 0 || relative === '.' || relative === '..') {
    return null;
  }
  return candidate;
}

function normalizePath(path: string): string {
  return path.replace(/\\/g, '/').replace(/\/+$/, '');
}
