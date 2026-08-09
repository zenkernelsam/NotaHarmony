export enum BitmapTransferKind {
  COMPLETED_LAYER = 0,
  ISOLATED_MASK = 1,
  PENCIL_TINT = 2,
  PENCIL_TEXTURE = 3,
}

export interface BitmapTransferMetrics {
  frameCount: number;
  fullFrameCount: number;
  totalTransfers: number;
  completedLayerTransfers: number;
  isolatedMaskTransfers: number;
  pencilTintTransfers: number;
  pencilTextureTransfers: number;
  lastFrameTransfers: number;
  maxFrameTransfers: number;
  lastDirtyRegionCount: number;
  maxDirtyRegionCount: number;
}

export class BitmapTransferTracker {
  private metrics: BitmapTransferMetrics = {
    frameCount: 0,
    fullFrameCount: 0,
    totalTransfers: 0,
    completedLayerTransfers: 0,
    isolatedMaskTransfers: 0,
    pencilTintTransfers: 0,
    pencilTextureTransfers: 0,
    lastFrameTransfers: 0,
    maxFrameTransfers: 0,
    lastDirtyRegionCount: 0,
    maxDirtyRegionCount: 0,
  };
  private transfersSinceLastFrame: number = 0;

  recordTransfer(kind: BitmapTransferKind): void {
    this.metrics.totalTransfers++;
    this.transfersSinceLastFrame++;
    if (kind === BitmapTransferKind.COMPLETED_LAYER) {
      this.metrics.completedLayerTransfers++;
    } else if (kind === BitmapTransferKind.ISOLATED_MASK) {
      this.metrics.isolatedMaskTransfers++;
    } else if (kind === BitmapTransferKind.PENCIL_TINT) {
      this.metrics.pencilTintTransfers++;
    } else {
      this.metrics.pencilTextureTransfers++;
    }
  }

  finishFrame(fullFrame: boolean, dirtyRegionCount: number): void {
    this.metrics.frameCount++;
    if (fullFrame) {
      this.metrics.fullFrameCount++;
    }
    this.metrics.lastFrameTransfers = this.transfersSinceLastFrame;
    this.metrics.maxFrameTransfers = Math.max(this.metrics.maxFrameTransfers, this.transfersSinceLastFrame);
    this.metrics.lastDirtyRegionCount = dirtyRegionCount;
    this.metrics.maxDirtyRegionCount = Math.max(this.metrics.maxDirtyRegionCount, dirtyRegionCount);
    this.transfersSinceLastFrame = 0;
  }

  snapshot(): BitmapTransferMetrics {
    return {
      frameCount: this.metrics.frameCount,
      fullFrameCount: this.metrics.fullFrameCount,
      totalTransfers: this.metrics.totalTransfers,
      completedLayerTransfers: this.metrics.completedLayerTransfers,
      isolatedMaskTransfers: this.metrics.isolatedMaskTransfers,
      pencilTintTransfers: this.metrics.pencilTintTransfers,
      pencilTextureTransfers: this.metrics.pencilTextureTransfers,
      lastFrameTransfers: this.metrics.lastFrameTransfers,
      maxFrameTransfers: this.metrics.maxFrameTransfers,
      lastDirtyRegionCount: this.metrics.lastDirtyRegionCount,
      maxDirtyRegionCount: this.metrics.maxDirtyRegionCount,
    };
  }
}
