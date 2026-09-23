// Phase 642 页级图像导出器：PixelMap → PNG/JPEG → 系统 picker 保存。
// 原版分享面板 s6d.JPG/PNG（atc case6/7）对选中页栅格化导出；
// Harmony 子集先覆盖当前页（页选择集合见 ADR-0609 登记差异）。
import { fileIo, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { ZipWriter } from './ZipArchive';

const FILE_WRITE_CHUNK_SIZE: number = 64 * 1024;
const FILE_READ_CHUNK_SIZE: number = 64 * 1024;
// 导出栅格经 packToData 的编码上限：4096×4096 RGBA 的最坏 PNG 远超
// 默认缓冲，显式放宽到 64MB。
const PACK_BUFFER_MAX_BYTES: number = 64 * 1024 * 1024;
const JPEG_QUALITY: number = 92;

export type ShareImageFormat = 'png' | 'jpeg';

export class PageImageExporter {
  // 栅格化页 → 编码 → 系统保存对话框；成功返回 true，取消/失败 false。
  async exportPageImage(context: common.UIAbilityContext, pixelMap: PixelMap,
    title: string, format: ShareImageFormat): Promise<boolean> {
    let tmpPath: string = '';
    let tmpFile: fileIo.File | null = null;
    let srcFile: fileIo.File | null = null;
    let dstFile: fileIo.File | null = null;
    try {
      const packer: image.ImagePacker = image.createImagePacker();
      let data: ArrayBuffer;
      try {
        data = await packer.packToData(pixelMap, {
          format: format === 'png' ? 'image/png' : 'image/jpeg',
          quality: format === 'jpeg' ? JPEG_QUALITY : 0,
          bufferSize: PACK_BUFFER_MAX_BYTES,
        });
      } finally {
        await packer.release();
      }
      const bytes: Uint8Array = new Uint8Array(data);
      const expectedSize: number = bytes.byteLength;
      const suffix: string = format === 'png' ? '.png' : '.jpg';
      tmpPath = `${context.tempDir}/page_export_${Date.now()}${suffix}`;
      tmpFile = fileIo.openSync(tmpPath,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      writeFileFully(tmpFile.fd, bytes, 'temporary page image export');
      fileIo.fsyncSync(tmpFile.fd);
      fileIo.closeSync(tmpFile);
      tmpFile = null;

      const documentPicker = new picker.DocumentViewPicker(context);
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [`${safeFileName(title)}_${Date.now()}${suffix}`];
      saveOptions.fileSuffixChoices = [format === 'png' ? 'PNG 图片|.png' : 'JPEG 图片|.jpg'];
      const uris: string[] = await documentPicker.save(saveOptions);
      if (uris.length === 0) {
        console.info('exportPageImage: user cancelled');
        return false;
      }
      const targetUri: string = uris[0];
      srcFile = fileIo.openSync(tmpPath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(tmpPath);
      const size: number = stat.size;
      if (!Number.isSafeInteger(size) || size !== expectedSize) {
        throw new Error(`temporary page export changed before copy: ${size}/${expectedSize} bytes`);
      }
      dstFile = fileIo.openSync(targetUri,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      copyFileFully(srcFile.fd, dstFile.fd, size, 'destination page image export');
      fileIo.fsyncSync(dstFile.fd);
      fileIo.closeSync(dstFile);
      dstFile = null;
      fileIo.closeSync(srcFile);
      srcFile = null;
      console.info(`exportPageImage success: bytes=${size} format=${format}`);
      return true;
    } catch (e) {
      console.error(`exportPageImage failed: ${JSON.stringify(e)}`);
      return false;
    } finally {
      if (tmpFile !== null) {
        try { fileIo.closeSync(tmpFile); } catch (_) { }
      }
      if (srcFile !== null) {
        try { fileIo.closeSync(srcFile); } catch (_) { }
      }
      if (dstFile !== null) {
        try { fileIo.closeSync(dstFile); } catch (_) { }
      }
      if (tmpPath.length > 0) {
        try {
          fileIo.unlinkSync(tmpPath);
        } catch (e) {
          // 忽略清理失败
        }
      }
    }
  }

  // Phase 644 整册图像导出：v6d.l 页集合=全部页面时，单文件 picker
  // 无法逐页分发 → 各页栅格打进一个 zip（page_001.<ext> 序），
  // 保存管线与单页路径同构。
  async exportPageImagesZip(context: common.UIAbilityContext,
    images: Uint8Array[], title: string, format: ShareImageFormat): Promise<boolean> {
    if (images.length === 0) {
      return false;
    }
    const suffix: string = format === 'png' ? 'png' : 'jpg';
    const writer: ZipWriter = new ZipWriter();
    for (let i = 0; i < images.length; i++) {
      const name: string = `page_${pad3(i + 1)}.${suffix}`;
      writer.addEntry(name, images[i], false);
    }
    let tmpPath: string = '';
    let tmpFile: fileIo.File | null = null;
    let srcFile: fileIo.File | null = null;
    let dstFile: fileIo.File | null = null;
    try {
      const zipBytes: Uint8Array = await writer.build();
      const expectedSize: number = zipBytes.byteLength;
      tmpPath = `${context.tempDir}/pages_export_${Date.now()}.zip`;
      tmpFile = fileIo.openSync(tmpPath,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      writeFileFully(tmpFile.fd, zipBytes, 'temporary pages zip export');
      fileIo.fsyncSync(tmpFile.fd);
      fileIo.closeSync(tmpFile);
      tmpFile = null;

      const documentPicker = new picker.DocumentViewPicker(context);
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [`${safeFileName(title)}_pages_${Date.now()}.zip`];
      saveOptions.fileSuffixChoices = ['ZIP 压缩包|.zip'];
      const uris: string[] = await documentPicker.save(saveOptions);
      if (uris.length === 0) {
        console.info('exportPageImagesZip: user cancelled');
        return false;
      }
      const targetUri: string = uris[0];
      srcFile = fileIo.openSync(tmpPath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(tmpPath);
      const size: number = stat.size;
      if (!Number.isSafeInteger(size) || size !== expectedSize) {
        throw new Error(`temporary zip export changed before copy: ${size}/${expectedSize} bytes`);
      }
      dstFile = fileIo.openSync(targetUri,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      copyFileFully(srcFile.fd, dstFile.fd, size, 'destination pages zip export');
      fileIo.fsyncSync(dstFile.fd);
      fileIo.closeSync(dstFile);
      dstFile = null;
      fileIo.closeSync(srcFile);
      srcFile = null;
      console.info(`exportPageImagesZip success: pages=${images.length} bytes=${size}`);
      return true;
    } catch (e) {
      console.error(`exportPageImagesZip failed: ${JSON.stringify(e)}`);
      return false;
    } finally {
      if (tmpFile !== null) {
        try { fileIo.closeSync(tmpFile); } catch (_) { }
      }
      if (srcFile !== null) {
        try { fileIo.closeSync(srcFile); } catch (_) { }
      }
      if (dstFile !== null) {
        try { fileIo.closeSync(dstFile); } catch (_) { }
      }
      if (tmpPath.length > 0) {
        try {
          fileIo.unlinkSync(tmpPath);
        } catch (e) {
          // 忽略清理失败
        }
      }
    }
  }
}

function pad3(value: number): string {
  let s: string = value.toString(10);
  while (s.length < 3) {
    s = `0${s}`;
  }
  return s;
}

function safeFileName(title: string): string {
  const cleaned: string = title.replace(/[\\/:*?"<>|]/g, '_').trim();
  return cleaned.length > 0 ? cleaned : 'page';
}

function writeFileFully(fd: number, bytes: Uint8Array, label: string): void {
  let total: number = 0;
  while (total < bytes.byteLength) {
    const end: number = Math.min(bytes.byteLength, total + FILE_WRITE_CHUNK_SIZE);
    const chunk: Uint8Array = bytes.subarray(total, end);
    const buffer: ArrayBuffer = chunk.buffer.slice(chunk.byteOffset,
      chunk.byteOffset + chunk.byteLength) as ArrayBuffer;
    const written: number = fileIo.writeSync(fd, buffer);
    if (written <= 0 || written > chunk.byteLength) {
      throw new Error(`${label} write made invalid progress: ${total}/${bytes.byteLength} bytes`);
    }
    total += written;
  }
}

function copyFileFully(sourceFd: number, destinationFd: number, size: number, label: string): void {
  if (!Number.isSafeInteger(size) || size < 0) {
    throw new Error(`${label} has an invalid size: ${size}`);
  }
  let total: number = 0;
  while (total < size) {
    const requested: number = Math.min(FILE_READ_CHUNK_SIZE, size - total);
    const chunkBuffer: ArrayBuffer = new ArrayBuffer(requested);
    const read: number = fileIo.readSync(sourceFd, chunkBuffer);
    if (read <= 0 || read > requested) {
      throw new Error(`${label} read made invalid progress: ${total}/${size} bytes`);
    }
    const chunk: Uint8Array = new Uint8Array(chunkBuffer, 0, read);
    const buffer: ArrayBuffer = chunk.buffer.slice(chunk.byteOffset,
      chunk.byteOffset + chunk.byteLength) as ArrayBuffer;
    writeFileFully(destinationFd, new Uint8Array(buffer), label);
    total += read;
  }
}
