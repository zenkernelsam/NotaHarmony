import { Point2D } from '../core/model/GeometryTypes';

export interface ThumbnailPageTransform {
  scale: number;
  offset: Point2D;
}

export function fitPageInThumbnail(pageWidth: number, pageHeight: number,
  thumbnailWidth: number, thumbnailHeight: number, margin: number): ThumbnailPageTransform {
  if (!Number.isFinite(pageWidth) || !Number.isFinite(pageHeight) || pageWidth <= 0 || pageHeight <= 0 ||
    !Number.isFinite(thumbnailWidth) || !Number.isFinite(thumbnailHeight) || thumbnailWidth <= 0 ||
    thumbnailHeight <= 0 || !Number.isFinite(margin) || margin < 0 || margin * 2 >= thumbnailWidth ||
    margin * 2 >= thumbnailHeight) {
    throw new Error('Invalid thumbnail geometry');
  }
  const scale: number = Math.min((thumbnailWidth - margin * 2) / pageWidth,
    (thumbnailHeight - margin * 2) / pageHeight);
  return {
    scale: scale,
    offset: {
      x: (thumbnailWidth - pageWidth * scale) / 2,
      y: (thumbnailHeight - pageHeight * scale) / 2,
    },
  };
}

export function thumbnailCacheKey(contentRevision: string, paperBackground: string,
  paperLineColor: string): string {
  return `${contentRevision}@${paperBackground}@${paperLineColor}`;
}

export function limitThumbnailNoteIds(noteIds: string[], maxCount: number): string[] {
  if (maxCount <= 0) {
    return [];
  }
  return noteIds.slice(0, maxCount);
}

export function prioritizeThumbnailNoteIds(noteIds: string[], priorityIds: string[], maxCount: number): string[] {
  if (maxCount <= 0) {
    return [];
  }
  const available: Set<string> = new Set<string>(noteIds);
  const seen: Set<string> = new Set<string>();
  const result: string[] = [];
  for (const noteId of priorityIds) {
    if (available.has(noteId) && !seen.has(noteId)) {
      result.push(noteId);
      seen.add(noteId);
      if (result.length >= maxCount) {
        return result;
      }
    }
  }
  for (const noteId of noteIds) {
    if (!seen.has(noteId)) {
      result.push(noteId);
      seen.add(noteId);
      if (result.length >= maxCount) {
        break;
      }
    }
  }
  return result;
}
