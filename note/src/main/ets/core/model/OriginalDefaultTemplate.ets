import {
  NoteBackgroundSettings, PageOrientation, PagePaperBackground, PaperSize, PaperTemplate,
} from './NoteTypes';
import {
  applyOriginalPaperSettings, cloneNoteBackgroundSettings, cloneOriginalPaper, clonePageBackground,
  originalDefaultNoteBackgroundSettings, originalPaperOrientation, templateForOriginalPaper,
  validateNoteBackgroundSettings,
} from './PageBackgroundModel';

export interface OriginalDefaultTemplateSelection {
  size: PaperSize;
  template: PaperTemplate;
  orientation: PageOrientation;
  paper: PagePaperBackground;
}

export function originalFallbackDefaultTemplate(): OriginalDefaultTemplateSelection {
  return originalDefaultTemplateFromSettings(applyOriginalPaperSettings(
    originalDefaultNoteBackgroundSettings(), PaperSize.LETTER,
    PaperTemplate.PLAIN, PageOrientation.PORTRAIT));
}

export function validateOriginalDefaultTemplate(value: OriginalDefaultTemplateSelection): void {
  if (value === null || value === undefined || !Number.isSafeInteger(value.size) ||
    value.size < PaperSize.A3 || value.size > PaperSize.TABLOID ||
    !Number.isSafeInteger(value.template) || value.template < PaperTemplate.PLAIN ||
    value.template > PaperTemplate.DOTS || !Number.isSafeInteger(value.orientation) ||
    value.orientation < PageOrientation.PORTRAIT ||
    value.orientation > PageOrientation.LANDSCAPE) {
    throw new Error('selected default template is invalid');
  }
  buildOriginalDefaultTemplateSettings(value);
}

// Mirrors o59.selectedDefaultTemplate -> l3a.a(mask=7): the preference stores paper
// selection, including color/spacing/legacy paper fields, while a new note receives a
// concrete paper-only nz9 with canonical size, zero rotation and 36 pt margins.
export function originalDefaultTemplateSettings(
  selection: OriginalDefaultTemplateSelection): NoteBackgroundSettings {
  validateOriginalDefaultTemplate(selection);
  return cloneNoteBackgroundSettings(buildOriginalDefaultTemplateSettings(selection));
}

export function originalDefaultTemplateFromSettings(
  settings: NoteBackgroundSettings): OriginalDefaultTemplateSelection {
  validateNoteBackgroundSettings(settings);
  const template: PaperTemplate = templateForOriginalPaper(settings.background.paper);
  const normalized: NoteBackgroundSettings = applyOriginalPaperSettings(
    originalDefaultNoteBackgroundSettings(), settings.size, template,
    originalPaperOrientation(settings.background));
  const paper: PagePaperBackground | null = cloneOriginalPaper(normalized.background.paper);
  if (paper === null) {
    throw new Error('selected default template normalization produced no paper');
  }
  const source: PagePaperBackground | null = settings.background.paper;
  paper.flairSpacingPt = source === null ? null : source.flairSpacingPt;
  paper.colorR = source === null ? null : source.colorR;
  paper.colorG = source === null ? null : source.colorG;
  paper.colorB = source === null ? null : source.colorB;
  paper.colorA = source === null ? null : source.colorA;
  paper.legacyPaperIndex = source === null ? null : source.legacyPaperIndex;
  const selection: OriginalDefaultTemplateSelection = {
    size: settings.size,
    template: template,
    orientation: originalPaperOrientation(settings.background),
    paper: paper,
  };
  validateOriginalDefaultTemplate(selection);
  return selection;
}

function buildOriginalDefaultTemplateSettings(
  selection: OriginalDefaultTemplateSelection): NoteBackgroundSettings {
  const settings: NoteBackgroundSettings = applyOriginalPaperSettings(
    originalDefaultNoteBackgroundSettings(), selection.size, selection.template,
    selection.orientation);
  const paper: PagePaperBackground | null = cloneOriginalPaper(selection.paper);
  if (paper === null || templateForOriginalPaper(paper) !== selection.template) {
    throw new Error('selected default template paper does not match its template');
  }
  settings.background.paper = paper;
  settings.registerBackground = clonePageBackground(settings.background);
  validateNoteBackgroundSettings(settings);
  if (settings.registerBackground === null ||
    (settings.background.pdf !== undefined && settings.background.pdf !== null)) {
    throw new Error('selected default template did not produce concrete paper settings');
  }
  return settings;
}
