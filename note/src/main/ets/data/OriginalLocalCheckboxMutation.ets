import {
  RichTextParagraphStyle, RichTextParagraphStyleRun, TextBlockElement,
} from '../core/model/ElementTypes';
import { cloneTextBlockElement } from '../core/model/TextBlockGeometry';
import { OriginalSequenceIdentity } from './OperationIdentity';
import {
  materializeOriginalTextCharacterOrder, StoredCharacter,
} from './OriginalInsertTextOperation';

export interface OriginalLocalCheckboxMutationPlan {
  location: OriginalSequenceIdentity;
  isChecked: boolean;
}

export function toggleOriginalCheckboxAt(text: TextBlockElement,
  codePointIndex: number): TextBlockElement | null {
  const scalars: number[] | null = strictScalars(text.richText);
  if (scalars === null || !isParagraphStart(scalars, codePointIndex)) {
    return null;
  }
  const styles: RichTextParagraphStyle[] | null = expandParagraphStyles(
    scalars.length, text.paragraphStyleRuns ?? []);
  if (styles === null || styles[codePointIndex].decoratorStyle !== 3) {
    return null;
  }
  styles[codePointIndex].isChecked = styles[codePointIndex].isChecked !== true;
  const result: TextBlockElement = cloneTextBlockElement(text);
  result.paragraphStyleRuns = collapseParagraphStyles(styles);
  return result;
}

export function planOriginalLocalCheckboxMutation(characters: StoredCharacter[],
  before: TextBlockElement, after: TextBlockElement): OriginalLocalCheckboxMutationPlan | null {
  if (before.richText !== after.richText ||
    JSON.stringify(before.characterStyleRuns ?? []) !==
      JSON.stringify(after.characterStyleRuns ?? [])) {
    return null;
  }
  const scalars: number[] | null = strictScalars(before.richText);
  const ordered: StoredCharacter[] | null = materializeOriginalTextCharacterOrder(characters);
  if (scalars === null || ordered === null) {
    return null;
  }
  const visible: StoredCharacter[] = ordered.filter(
    (character: StoredCharacter): boolean => character.visible);
  if (visible.length !== scalars.length) {
    return null;
  }
  for (let index: number = 0; index < visible.length; index++) {
    if (visible[index].scalar !== scalars[index]) {
      return null;
    }
  }
  let result: OriginalLocalCheckboxMutationPlan | null = null;
  for (let index: number = 0; index < scalars.length; index++) {
    if (!isParagraphStart(scalars, index)) {
      continue;
    }
    const toggled: TextBlockElement | null = toggleOriginalCheckboxAt(before, index);
    if (toggled === null || JSON.stringify(toggled.paragraphStyleRuns ?? []) !==
      JSON.stringify(after.paragraphStyleRuns ?? [])) {
      continue;
    }
    if (result !== null) {
      return null;
    }
    const style: RichTextParagraphStyle | null = paragraphStyleAt(
      toggled.paragraphStyleRuns ?? [], index);
    if (style === null || style.isChecked === undefined) {
      return null;
    }
    result = {
      location: cloneIdentity(visible[index].identity), isChecked: style.isChecked,
    };
  }
  return result;
}

function expandParagraphStyles(length: number,
  runs: RichTextParagraphStyleRun[]): RichTextParagraphStyle[] | null {
  const result: RichTextParagraphStyle[] = [];
  for (let index: number = 0; index < length; index++) {
    result.push({});
  }
  let previousEnd: number = 0;
  for (const run of runs) {
    if (!Number.isSafeInteger(run.start) || !Number.isSafeInteger(run.end) ||
      run.start < previousEnd || run.start < 0 || run.end <= run.start || run.end > length ||
      run.style === null || typeof run.style !== 'object') {
      return null;
    }
    for (let index: number = run.start; index < run.end; index++) {
      result[index] = cloneParagraphStyle(run.style);
    }
    previousEnd = run.end;
  }
  return result;
}

function collapseParagraphStyles(styles: RichTextParagraphStyle[]): RichTextParagraphStyleRun[] {
  const result: RichTextParagraphStyleRun[] = [];
  for (let index: number = 0; index < styles.length; index++) {
    const style: RichTextParagraphStyle = styles[index];
    if (Object.keys(style).length === 0) {
      continue;
    }
    const previous: RichTextParagraphStyleRun | undefined = result[result.length - 1];
    if (previous !== undefined && previous.end === index &&
      JSON.stringify(previous.style) === JSON.stringify(style)) {
      previous.end++;
    } else {
      result.push({ start: index, end: index + 1, style: cloneParagraphStyle(style) });
    }
  }
  return result;
}

function paragraphStyleAt(runs: RichTextParagraphStyleRun[],
  index: number): RichTextParagraphStyle | null {
  for (const run of runs) {
    if (index >= run.start && index < run.end) {
      return run.style;
    }
  }
  return null;
}

function cloneParagraphStyle(style: RichTextParagraphStyle): RichTextParagraphStyle {
  const result: RichTextParagraphStyle = {};
  if (style.indentLevel !== undefined) result.indentLevel = style.indentLevel;
  if (style.alignment !== undefined) result.alignment = style.alignment;
  if (style.lineSpacing !== undefined) result.lineSpacing = style.lineSpacing;
  if (style.decoratorStyle !== undefined) result.decoratorStyle = style.decoratorStyle;
  if (style.programmingLanguage !== undefined) {
    result.programmingLanguage = style.programmingLanguage;
  }
  if (style.writingDirection !== undefined) result.writingDirection = style.writingDirection;
  if (style.isChecked !== undefined) result.isChecked = style.isChecked;
  return result;
}

function isParagraphStart(scalars: number[], index: number): boolean {
  return Number.isSafeInteger(index) && index >= 0 && index < scalars.length &&
    (index === 0 || scalars[index - 1] === 0x0A);
}

function strictScalars(value: string): number[] | null {
  const result: number[] = [];
  for (let index: number = 0; index < value.length;) {
    const scalar: number = value.codePointAt(index) as number;
    if (scalar < 0 || scalar > 0x10FFFF || (scalar >= 0xD800 && scalar <= 0xDFFF)) {
      return null;
    }
    result.push(scalar);
    index += scalar > 0xFFFF ? 2 : 1;
  }
  return result;
}

function cloneIdentity(identity: OriginalSequenceIdentity): OriginalSequenceIdentity {
  return { timestamp: identity.timestamp, siteId: identity.siteId, index: identity.index };
}
