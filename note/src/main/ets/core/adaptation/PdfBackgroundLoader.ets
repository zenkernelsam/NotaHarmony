import { image } from '@kit.ImageKit';
import { pdfService } from '@kit.PDFKit';
import { AssetStatus, NoteAsset } from '../model/AssetTypes';
import { originalAssetHashKey, originalAssetStorageHash } from '../model/ImageBlockGeometry';
import { PagePdfBackground } from '../model/NoteTypes';
import { AssetRepositoryImpl } from '../../data/AssetRepositoryImpl';
import { DatabaseManager } from '../../data/DatabaseManager';

export enum PdfBackgroundLoadState {
  MISSING = 0,
  PENDING = 1,
  READY = 2,
  FAILED = 3,
}

export interface LoadedPdfBackground {
  state: PdfBackgroundLoadState;
  storageHash: string;
  bitmap: ImageBitmap | null;
  pixelMap: image.PixelMap | null;
  error: string | null;
}

export class PdfBackgroundLoader {
  private repository: AssetRepositoryImpl;

  constructor(database: DatabaseManager) {
    this.repository = new AssetRepositoryImpl(database);
  }

  async load(pdf: PagePdfBackground): Promise<LoadedPdfBackground> {
    const storageHash: string = originalAssetStorageHash(pdf.metadata.assetHashBits);
    const legacyHash: string = originalAssetHashKey(pdf.metadata.assetHashBits);
    let asset: NoteAsset | null = await this.repository.getAsset(storageHash);
    if (asset === null && legacyHash !== storageHash) {
      asset = await this.repository.getAsset(legacyHash);
    }
    if (asset === null) {
      return this.empty(PdfBackgroundLoadState.MISSING, storageHash, 'PDF asset metadata is absent');
    }
    if (asset.fileSize !== pdf.metadata.fileSize ||
      asset.mimeType.toLowerCase() !== pdf.metadata.mimeType.toLowerCase()) {
      return this.empty(PdfBackgroundLoadState.FAILED, storageHash, 'PDF asset metadata conflicts');
    }
    if (asset.status === AssetStatus.FAILED) {
      return this.empty(PdfBackgroundLoadState.FAILED, storageHash, 'PDF asset is marked failed');
    }
    if (asset.localPath === null || asset.localPath.length === 0) {
      return this.empty(PdfBackgroundLoadState.PENDING, storageHash, 'PDF asset has no local file yet');
    }
    return this.renderLocalPage(asset.localPath, pdf, storageHash);
  }

  release(loaded: LoadedPdfBackground): void {
    if (loaded.bitmap !== null) {
      loaded.bitmap.close();
      loaded.bitmap = null;
    }
    if (loaded.pixelMap !== null) {
      loaded.pixelMap.release().catch((error: Object) => {
        console.warn(`PDF background PixelMap release failed: ${JSON.stringify(error)}`);
      });
      loaded.pixelMap = null;
    }
  }

  private renderLocalPage(path: string, pdf: PagePdfBackground,
    storageHash: string): LoadedPdfBackground {
    const document: pdfService.PdfDocument = new pdfService.PdfDocument();
    let pixelMap: image.PixelMap | null = null;
    try {
      const parsed: pdfService.ParseResult = document.loadDocument(path);
      if (parsed !== pdfService.ParseResult.PARSE_SUCCESS) {
        return this.empty(PdfBackgroundLoadState.FAILED, storageHash,
          `PDFKit parse failed with result ${parsed}`);
      }
      if (document.getPageCount() !== pdf.totalPageCount || pdf.pageInAsset >= document.getPageCount()) {
        return this.empty(PdfBackgroundLoadState.FAILED, storageHash,
          'PDF document page count conflicts with metadata');
      }
      pixelMap = document.getPage(pdf.pageInAsset).getPagePixelMap();
      return {
        state: PdfBackgroundLoadState.READY,
        storageHash: storageHash,
        bitmap: new ImageBitmap(pixelMap),
        pixelMap: pixelMap,
        error: null,
      };
    } catch (error) {
      if (pixelMap !== null) {
        pixelMap.release().catch((_releaseError: Object) => {
        });
      }
      return this.empty(PdfBackgroundLoadState.FAILED, storageHash, JSON.stringify(error));
    } finally {
      document.releaseDocument();
    }
  }

  private empty(state: PdfBackgroundLoadState, storageHash: string,
    error: string): LoadedPdfBackground {
    return { state: state, storageHash: storageHash, bitmap: null, pixelMap: null, error: error };
  }
}
