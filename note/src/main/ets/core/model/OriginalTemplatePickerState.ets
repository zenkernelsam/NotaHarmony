import {
  NoteBackgroundSettings, PageOrientation, PagePaperBackground, PaperSize, PaperTemplate,
} from './NoteTypes';
import {
  applyOriginalPaperSettings, clonePageBackground, validateNoteBackgroundSettings,
} from './PageBackgroundModel';
import {
  OriginalBackgroundInfo, OriginalPaperBackground, originalPaperLineTypeFromTemplate,
  originalPaperSpacingPointsFromInches, packOriginalArgb, paperTemplateFromOriginalLineType,
  validateOriginalBackgroundInfo, validateOriginalPaperBackground,
} from './OriginalPaperSettings';

export interface OriginalTemplatePickerDraft {
  size: PaperSize;
  orientation: PageOrientation;
}

export function originalTemplatePickerDraft(
  settings: NoteBackgroundSettings): OriginalTemplatePickerDraft {
  validateNoteBackgroundSettings(settings);
  return { size: settings.size, orientation: settings.orientation };
}

export function stageOriginalTemplateSize(draft: OriginalTemplatePickerDraft,
  size: PaperSize): OriginalTemplatePickerDraft {
  validateDraft(draft);
  validateSize(size);
  return { size: size, orientation: draft.orientation };
}

export function stageOriginalTemplateOrientation(draft: OriginalTemplatePickerDraft,
  orientation: PageOrientation): OriginalTemplatePickerDraft {
  validateDraft(draft);
  validateOrientation(orientation);
  return { size: draft.size, orientation: orientation };
}

// Original rge/vge keep paper size/orientation in a draft s3a. The persisted/default or
// current-note l3a changes only when a paper-line card is selected. Preserve the current
// paper color and legacy index; for the same line style, preserve its configured spacing.
export function applyOriginalTemplatePickerSelection(current: NoteBackgroundSettings,
  draft: OriginalTemplatePickerDraft, template: PaperTemplate,
  backgroundInfo?: OriginalBackgroundInfo): NoteBackgroundSettings {
  validateNoteBackgroundSettings(current);
  validateDraft(draft);
  validateTemplate(template);
  let normalizedInfo: OriginalBackgroundInfo | null = null;
  if (backgroundInfo !== undefined) {
    normalizedInfo = validateOriginalBackgroundInfo(backgroundInfo);
    if (normalizedInfo.paperLineType !== originalPaperLineTypeFromTemplate(template)) {
      throw new Error('original picker background info does not match the selected template');
    }
  }
  const selected: NoteBackgroundSettings = applyOriginalPaperSettings(
    current, draft.size, template, draft.orientation);
  const source = current.background.paper;
  const target = selected.background.paper;
  if (source !== null && target !== null) {
    target.colorR = source.colorR;
    target.colorG = source.colorG;
    target.colorB = source.colorB;
    target.colorA = source.colorA;
    target.legacyPaperIndex = source.legacyPaperIndex;
    if (normalizedInfo !== null) {
      target.flairSpacingPt = normalizedInfo.spacingInches === null ? null :
        originalPaperSpacingPointsFromInches(normalizedInfo.spacingInches);
    } else if (template === current.template) {
      target.flairSpacingPt = source.flairSpacingPt;
    }
    selected.registerBackground = clonePageBackground(selected.background);
  }
  validateNoteBackgroundSettings(selected);
  return selected;
}

// Build the exact l3a semantic candidate used by the original favorite/unfavorite callbacks.
// The draft paper size/orientation and shared gq0 spacing are combined only at this boundary.
export function originalTemplatePickerFavorite(current: NoteBackgroundSettings,
  draft: OriginalTemplatePickerDraft,
  backgroundInfo: OriginalBackgroundInfo): OriginalPaperBackground {
  const normalizedInfo: OriginalBackgroundInfo = validateOriginalBackgroundInfo(backgroundInfo);
  const selected: NoteBackgroundSettings = applyOriginalTemplatePickerSelection(
    current, draft, paperTemplateFromOriginalLineType(normalizedInfo.paperLineType), normalizedInfo);
  const paper: PagePaperBackground | null = selected.background.paper;
  let backgroundColor: number | null = null;
  let legacyPaperIndex: number | null = null;
  if (paper !== null) {
    legacyPaperIndex = paper.legacyPaperIndex;
    const colorCount: number = (paper.colorR === null ? 0 : 1) +
      (paper.colorG === null ? 0 : 1) + (paper.colorB === null ? 0 : 1) +
      (paper.colorA === null ? 0 : 1);
    if (colorCount === 4) {
      backgroundColor = packOriginalArgb(paper.colorR as number, paper.colorG as number,
        paper.colorB as number, paper.colorA as number);
    } else if (colorCount !== 0) {
      throw new Error('original picker paper color is incomplete');
    }
  }
  return validateOriginalPaperBackground({
    id: 0,
    paperSize: draft.size,
    paperOrientation: draft.orientation,
    backgroundColor: backgroundColor,
    legacyPaperIndex: legacyPaperIndex,
    paperLineType: normalizedInfo.paperLineType,
    spacingInches: normalizedInfo.spacingInches,
    hasOptions: normalizedInfo.hasOptions,
  });
}

export function isOriginalTemplatePickerSelection(settings: NoteBackgroundSettings,
  draft: OriginalTemplatePickerDraft, template: PaperTemplate,
  backgroundInfo?: OriginalBackgroundInfo): boolean {
  validateNoteBackgroundSettings(settings);
  validateDraft(draft);
  validateTemplate(template);
  if (settings.size !== draft.size || settings.orientation !== draft.orientation ||
    settings.template !== template) {
    return false;
  }
  if (backgroundInfo === undefined) {
    return true;
  }
  const normalizedInfo: OriginalBackgroundInfo = validateOriginalBackgroundInfo(backgroundInfo);
  if (normalizedInfo.paperLineType !== originalPaperLineTypeFromTemplate(template)) {
    throw new Error('original picker background info does not match the selected template');
  }
  const paper: PagePaperBackground | null = settings.background.paper;
  if (paper === null) {
    return false;
  }
  const expectedSpacing: number | null = normalizedInfo.spacingInches === null ? null :
    originalPaperSpacingPointsFromInches(normalizedInfo.spacingInches);
  return paper.flairSpacingPt === expectedSpacing;
}

function validateDraft(draft: OriginalTemplatePickerDraft): void {
  if (draft === null || draft === undefined) {
    throw new Error('original template picker draft is invalid');
  }
  validateSize(draft.size);
  validateOrientation(draft.orientation);
}

function validateSize(size: PaperSize): void {
  if (!Number.isSafeInteger(size) || size < PaperSize.A3 || size > PaperSize.TABLOID) {
    throw new Error('original template picker size is invalid');
  }
}

function validateOrientation(orientation: PageOrientation): void {
  if (!Number.isSafeInteger(orientation) || orientation < PageOrientation.PORTRAIT ||
    orientation > PageOrientation.LANDSCAPE) {
    throw new Error('original template picker orientation is invalid');
  }
}

function validateTemplate(template: PaperTemplate): void {
  if (!Number.isSafeInteger(template) || template < PaperTemplate.PLAIN ||
    template > PaperTemplate.DOTS) {
    throw new Error('original template picker paper style is invalid');
  }
}
