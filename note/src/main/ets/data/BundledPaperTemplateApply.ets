// Phase 1401 bundled paper-template apply path — mirrors original f1d/sqc.b:
// stage the bundled PDF asset (rawfile) -> content-addressed asset store
// (storeImportedOriginalAsset) -> PageBackground.pdf register
// (pdn.c asset+pageCount+cropBoxes+FIT_AND_CROP_BOX) -> page update.
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { pdfService } from '@kit.PDFKit';
import { image } from '@kit.ImageKit';
import {
  BundledPaperVariant,
} from '../core/model/PaperTemplateCatalog';
import {
  OriginalAssetMetadata, PageBackground, PdfLayoutBehavior,
} from '../core/model/NoteTypes';
import { PAGE_BACKGROUND_SCHEMA_VERSION } from '../core/model/PageBackgroundModel';
import { releasePdfNativeResources } from '../core/adaptation/PdfBackgroundLoader';
import { sha512Digest, originalAssetHashBitsFromSha512 } from './AssetDigest';
import { storeImportedOriginalAsset } from './ImageAssetPackageStore';
import { DatabaseManager } from './DatabaseManager';

const BUNDLED_TEMPLATE_STAGING_PREFIX: string = 'bundled_template';
const BUNDLED_TEMPLATE_MIME: string = 'application/pdf';
const WRITE_CHUNK_SIZE: number = 64 * 1024;

export interface BundledTemplateApplyResult {
  background: PageBackground | null;
  error: string | null;
}

function bundledTemplateWriteFully(path: string, data: Uint8Array): void {
  const file: fileIo.File = fileIo.openSync(path,
    fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  try {
    let offset: number = 0;
    while (offset < data.length) {
      const end: number = Math.min(data.length, offset + WRITE_CHUNK_SIZE);
      const view: Uint8Array = data.subarray(offset, end);
      const chunk: ArrayBuffer = view.buffer.slice(view.byteOffset,
        view.byteOffset + view.byteLength) as ArrayBuffer;
      const written: number = fileIo.writeSync(file.fd, chunk);
      if (written <= 0 || written > view.byteLength) {
        throw new Error(`bundled template staging write is incomplete: ${offset}/${data.length}`);
      }
      offset += written;
    }
    fileIo.fsyncSync(file.fd);
  } finally {
    fileIo.closeSync(file);
  }
}

// sqc.d: copy the bundled asset to a sandbox file PDFKit can parse, then hand
// the parsed dimensions + imported asset to the page-background register.
// Fail-closed: any staging/parse/store failure returns error instead of a
// partially applied background.
export async function buildBundledTemplatePageBackground(
  context: common.UIAbilityContext, database: DatabaseManager, noteId: string,
  variant: BundledPaperVariant): Promise<BundledTemplateApplyResult> {
  const pendingDirectory: string = database.getFilesDir() + '/assets/pending';
  const stagingPath: string = pendingDirectory +
    `/${BUNDLED_TEMPLATE_STAGING_PREFIX}_${Date.now()}_${Math.floor(Math.random() * 0x1000000)}.pdf`;
  const document: pdfService.PdfDocument = new pdfService.PdfDocument();
  let page: pdfService.PdfPage | null = null;
  try {
    const bytes: Uint8Array = await context.resourceManager.getRawFileContent(
      variant.rawfilePath);
    fileIo.mkdirSync(pendingDirectory, true);
    bundledTemplateWriteFully(stagingPath, bytes);
    const parsed: pdfService.ParseResult = document.loadDocument(stagingPath);
    if (parsed !== pdfService.ParseResult.PARSE_SUCCESS) {
      return { background: null, error: `PDFKit parse failed with result ${parsed}` };
    }
    const pageCount: number = document.getPageCount();
    if (pageCount !== 1) {
      return { background: null,
        error: `bundled template page count is not 1: ${pageCount}` };
    }
    page = document.getPage(0);
    const widthPt: number = page.getWidth();
    const heightPt: number = page.getHeight();
    const digestBytes: Uint8Array = await sha512Digest(bytes);
    const metadata: OriginalAssetMetadata = {
      assetHashBits: originalAssetHashBitsFromSha512(digestBytes),
      fileName: variant.rawfilePath.substring(variant.rawfilePath.lastIndexOf('/') + 1),
      mimeType: BUNDLED_TEMPLATE_MIME,
      fileSize: bytes.length,
    };
    await storeImportedOriginalAsset(database, metadata, bytes, noteId);
    const background: PageBackground = {
      schemaVersion: PAGE_BACKGROUND_SCHEMA_VERSION,
      paper: null,
      pdf: {
        metadata: metadata,
        layoutBehavior: PdfLayoutBehavior.FIT_AND_CROP_BOX,
        totalPageCount: pageCount,
        pagesConsumed: pageCount,
        pageOffset: 0,
        cropBoxes: [{ widthPt: widthPt, heightPt: heightPt }],
        pageInAsset: 0,
      },
      rotationRadians: 0,
      sourceWidthPt: widthPt,
      sourceHeightPt: heightPt,
      margins: null,
    };
    return { background: background, error: null };
  } catch (error) {
    return { background: null, error: JSON.stringify(error) };
  } finally {
    let releasePage: (() => void) | null = null;
    if (page !== null) {
      const pageToRelease: pdfService.PdfPage = page;
      releasePage = (): void => pageToRelease.release();
    }
    const releaseResult = releasePdfNativeResources(
      releasePage, (): void => document.releaseDocument());
    if (releaseResult.pageError !== null) {
      console.warn(`bundled template page release failed: ${releaseResult.pageError}`);
    }
    if (releaseResult.documentError !== null) {
      console.warn(`bundled template document release failed: ${releaseResult.documentError}`);
    }
    try {
      if (fileIo.accessSync(stagingPath)) {
        fileIo.unlinkSync(stagingPath);
      }
    } catch (_cleanupError) {
    }
  }
}

// Original zgc.b picks thumb.(heic|png) per variant; Harmony has no HEIC
// pipeline, so gallery cells rasterize the resolved variant's PDF page instead
// (ADR-1337). Same staging + two-level release contract as the apply path.
export async function loadBundledTemplateThumb(
  context: common.UIAbilityContext, database: DatabaseManager,
  variant: BundledPaperVariant): Promise<image.PixelMap | null> {
  const pendingDirectory: string = database.getFilesDir() + '/assets/pending';
  const stagingPath: string = pendingDirectory +
    `/bundled_thumb_${Date.now()}_${Math.floor(Math.random() * 0x1000000)}.pdf`;
  const document: pdfService.PdfDocument = new pdfService.PdfDocument();
  let page: pdfService.PdfPage | null = null;
  let documentReleased: boolean = false;
  try {
    const bytes: Uint8Array = await context.resourceManager.getRawFileContent(
      variant.rawfilePath);
    fileIo.mkdirSync(pendingDirectory, true);
    bundledTemplateWriteFully(stagingPath, bytes);
    const parsed: pdfService.ParseResult = document.loadDocument(stagingPath);
    if (parsed !== pdfService.ParseResult.PARSE_SUCCESS) {
      return null;
    }
    if (document.getPageCount() < 1) {
      return null;
    }
    page = document.getPage(0);
    const pixelMap: image.PixelMap = page.getPagePixelMap();
    const releasedPage: pdfService.PdfPage = page;
    page = null;
    try {
      releasedPage.release();
    } catch (pageError) {
      console.warn(`bundled template thumb page release failed: ${JSON.stringify(pageError)}`);
    }
    try {
      document.releaseDocument();
      documentReleased = true;
    } catch (docError) {
      console.warn(`bundled template thumb document release failed: ${JSON.stringify(docError)}`);
    }
    return pixelMap;
  } catch (error) {
    console.warn(`bundled template thumb load failed: ${JSON.stringify(error)}`);
    return null;
  } finally {
    if (page !== null) {
      try {
        page.release();
      } catch (_pageError) {
      }
    }
    if (!documentReleased) {
      try {
        document.releaseDocument();
      } catch (_docError) {
      }
    }
    try {
      if (fileIo.accessSync(stagingPath)) {
        fileIo.unlinkSync(stagingPath);
      }
    } catch (_cleanupError) {
    }
  }
}
