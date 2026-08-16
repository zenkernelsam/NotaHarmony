import {
  NoteBackgroundSettings, PageOrientation, PaperSize, PaperTemplate,
} from './NoteTypes';
import {
  applyOriginalPaperSettings, clonePageBackground, validateNoteBackgroundSettings,
} from './PageBackgroundModel';

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
  draft: OriginalTemplatePickerDraft, template: PaperTemplate): NoteBackgroundSettings {
  validateNoteBackgroundSettings(current);
  validateDraft(draft);
  validateTemplate(template);
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
    if (template === current.template) {
      target.flairSpacingPt = source.flairSpacingPt;
    }
    selected.registerBackground = clonePageBackground(selected.background);
  }
  validateNoteBackgroundSettings(selected);
  return selected;
}

export function isOriginalTemplatePickerSelection(settings: NoteBackgroundSettings,
  draft: OriginalTemplatePickerDraft, template: PaperTemplate): boolean {
  validateNoteBackgroundSettings(settings);
  validateDraft(draft);
  validateTemplate(template);
  return settings.size === draft.size && settings.orientation === draft.orientation &&
    settings.template === template;
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
