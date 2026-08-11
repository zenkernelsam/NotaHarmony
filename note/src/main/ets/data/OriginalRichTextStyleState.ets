import { relationalStore } from '@kit.ArkData';
import {
  RichTextCharacterStyle, RichTextCharacterStyleRun, RichTextParagraphStyle,
  RichTextParagraphStyleRun,
} from '../core/model/ElementTypes';
import {
  compareOperationIdentity, compareOriginalSequenceIdentity, encodeOriginalSequenceId,
  OperationIdentity, OriginalSequenceIdentity, validateOperationIdentity,
  validateOriginalSequenceIdentity,
} from './OperationIdentity';

export enum OriginalTextBoundaryType {
  BEFORE = 0,
  AFTER = 1,
  START_OF_DOC = 2,
  END_OF_DOC = 3,
}

export interface OriginalTextBoundary {
  location: OriginalSequenceIdentity;
  type: OriginalTextBoundaryType;
}

export interface OriginalTextStyleAttributes {
  boldPresent: boolean;
  bold: boolean | null;
  italicPresent: boolean;
  italic: boolean | null;
  underlinePresent: boolean;
  underline: boolean | null;
  highlightColorPresent: boolean;
  highlightColor: number | null;
  familyNamePresent: boolean;
  familyName: string | null;
  fontSizePresent: boolean;
  fontSize: number | null;
  foregroundColorPresent: boolean;
  foregroundColor: number | null;
  linkPresent: boolean;
  link: string | null;
  superscriptPresent: boolean;
  superscript: boolean | null;
  subscriptPresent: boolean;
  subscript: boolean | null;
  strikethroughPresent: boolean;
  strikethrough: boolean | null;
  indentLevelPresent: boolean;
  indentLevel: number | null;
  alignmentPresent: boolean;
  alignment: number | null;
  lineSpacingPresent: boolean;
  lineSpacing: number | null;
  decoratorStylePresent: boolean;
  decoratorStyle: number | null;
  programmingLanguagePresent: boolean;
  programmingLanguage: string | null;
  writingDirectionPresent: boolean;
  writingDirection: number | null;
}

export interface StoredOriginalTextCharacter {
  identity: OriginalSequenceIdentity;
  parent: OriginalSequenceIdentity | null;
  scalar: number;
  visible: boolean;
  visibilityWinner: OperationIdentity | null;
}

export interface StoredOriginalTextStyleOperation {
  identity: OperationIdentity;
  paragraph: boolean;
  clearAll: boolean;
  start: OriginalTextBoundary;
  end: OriginalTextBoundary;
  attributes: OriginalTextStyleAttributes;
}

export interface StoredOriginalCheckboxState {
  location: OriginalSequenceIdentity;
  isChecked: boolean;
  winner: OperationIdentity;
}

export interface OriginalTextStyleMaterialization {
  characterRuns: RichTextCharacterStyleRun[];
  paragraphRuns: RichTextParagraphStyleRun[];
}

export async function readOriginalTextStyleOperations(store: relationalStore.RdbStore,
  noteId: string, block: OperationIdentity): Promise<StoredOriginalTextStyleOperation[] | null> {
  const rows = await store.querySql(
    `SELECT operation_timestamp, operation_site_id, paragraph, clear_all,
            start_timestamp, start_site_id, start_index, start_type,
            end_timestamp, end_site_id, end_index, end_type, attributes_json
     FROM original_text_style_operation
     WHERE note_id = ? AND block_timestamp = ? AND block_site_id = ?`,
    [noteId, block.timestamp, block.siteId]);
  const result: StoredOriginalTextStyleOperation[] = [];
  try {
    while (rows.goToNextRow()) {
      const identity: OperationIdentity = {
        timestamp: rows.getLong(rows.getColumnIndex('operation_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('operation_site_id')),
      };
      validateOperationIdentity(identity);
      const start: OriginalTextBoundary = readBoundaryRow(rows, 'start');
      const end: OriginalTextBoundary = readBoundaryRow(rows, 'end');
      const paragraph: number = rows.getLong(rows.getColumnIndex('paragraph'));
      const clearAll: number = rows.getLong(rows.getColumnIndex('clear_all'));
      if ((paragraph !== 0 && paragraph !== 1) || (clearAll !== 0 && clearAll !== 1)) {
        return null;
      }
      const attributes = JSON.parse(rows.getString(rows.getColumnIndex('attributes_json'))) as
        OriginalTextStyleAttributes;
      if (!validateAttributes(attributes, paragraph === 1, clearAll === 1)) {
        return null;
      }
      result.push({ identity: identity, paragraph: paragraph === 1, clearAll: clearAll === 1,
        start: start, end: end, attributes: attributes });
    }
  } catch (_error) {
    return null;
  } finally {
    rows.close();
  }
  result.sort((left: StoredOriginalTextStyleOperation,
    right: StoredOriginalTextStyleOperation): number =>
    compareOperationIdentity(left.identity, right.identity));
  return result;
}

export async function readOriginalCheckboxStates(store: relationalStore.RdbStore,
  noteId: string, block: OperationIdentity): Promise<StoredOriginalCheckboxState[] | null> {
  const rows = await store.querySql(
    `SELECT location_timestamp, location_site_id, location_index, is_checked,
            winner_timestamp, winner_site_id
     FROM original_text_checkbox_state
     WHERE note_id = ? AND block_timestamp = ? AND block_site_id = ?`,
    [noteId, block.timestamp, block.siteId]);
  const result: StoredOriginalCheckboxState[] = [];
  const winners: Set<string> = new Set<string>();
  try {
    while (rows.goToNextRow()) {
      const location: OriginalSequenceIdentity = {
        timestamp: rows.getLong(rows.getColumnIndex('location_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('location_site_id')),
        index: rows.getLong(rows.getColumnIndex('location_index')),
      };
      const winner: OperationIdentity = {
        timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      };
      validateOriginalSequenceIdentity(location);
      validateOperationIdentity(winner);
      const checked: number = rows.getLong(rows.getColumnIndex('is_checked'));
      const winnerKey: string = `${winner.timestamp}:${winner.siteId}`;
      if ((checked !== 0 && checked !== 1) || winners.has(winnerKey)) {
        return null;
      }
      winners.add(winnerKey);
      result.push({ location: location, isChecked: checked === 1, winner: winner });
    }
    return result;
  } catch (_error) {
    return null;
  } finally {
    rows.close();
  }
}

export function materializeOriginalTextStyles(characters: StoredOriginalTextCharacter[],
  operations: StoredOriginalTextStyleOperation[], checkboxStates: StoredOriginalCheckboxState[] = []):
  OriginalTextStyleMaterialization | null {
  const ordered: StoredOriginalTextCharacter[] | null = orderCharacters(characters);
  if (ordered === null) {
    return null;
  }
  const positions: Map<string, number> = new Map<string, number>();
  for (let index: number = 0; index < ordered.length; index++) {
    positions.set(encodeOriginalSequenceId(ordered[index].identity), index);
  }
  const checkboxByLocation: Map<string, StoredOriginalCheckboxState> = new Map();
  const checkboxWinners: Set<string> = new Set<string>();
  for (const state of checkboxStates) {
    try {
      validateOriginalSequenceIdentity(state.location);
      validateOperationIdentity(state.winner);
    } catch (_error) {
      return null;
    }
    const locationKey: string = encodeOriginalSequenceId(state.location);
    const winnerKey: string = `${state.winner.timestamp}:${state.winner.siteId}`;
    if (!positions.has(locationKey) || checkboxByLocation.has(locationKey) ||
      checkboxWinners.has(winnerKey)) {
      return null;
    }
    checkboxByLocation.set(locationKey, state);
    checkboxWinners.add(winnerKey);
  }
  const sorted: StoredOriginalTextStyleOperation[] = operations.slice();
  sorted.sort((left: StoredOriginalTextStyleOperation,
    right: StoredOriginalTextStyleOperation): number =>
    compareOperationIdentity(left.identity, right.identity));
  const characterRuns: RichTextCharacterStyleRun[] = [];
  const paragraphRuns: RichTextParagraphStyleRun[] = [];
  let visibleIndex: number = 0;
  for (let index: number = 0; index < ordered.length; index++) {
    const character: StoredOriginalTextCharacter = ordered[index];
    if (!character.visible) {
      continue;
    }
    let characterStyle: RichTextCharacterStyle = {};
    let paragraphStyle: RichTextParagraphStyle = {};
    for (const operation of sorted) {
      const range: number[] | null = resolveRange(operation, positions, ordered.length);
      if (range === null) {
        return null;
      }
      if (index < range[0] || index >= range[1]) {
        continue;
      }
      if (operation.paragraph) {
        if (operation.clearAll) {
          paragraphStyle = {};
        } else {
          paragraphStyle = applyParagraphAttributes(paragraphStyle, operation.attributes);
        }
      } else if (operation.clearAll) {
        characterStyle = {};
      } else {
        characterStyle = applyCharacterAttributes(characterStyle, operation.attributes);
      }
    }
    const checkbox: StoredOriginalCheckboxState | undefined = checkboxByLocation.get(
      encodeOriginalSequenceId(character.identity));
    if (checkbox !== undefined && paragraphStyle.decoratorStyle === 3) {
      paragraphStyle.isChecked = checkbox.isChecked;
    }
    appendCharacterRun(characterRuns, visibleIndex, characterStyle);
    appendParagraphRun(paragraphRuns, visibleIndex, paragraphStyle);
    visibleIndex++;
  }
  return { characterRuns: characterRuns, paragraphRuns: paragraphRuns };
}

export function emptyOriginalTextStyleAttributes(): OriginalTextStyleAttributes {
  return {
    boldPresent: false, bold: null, italicPresent: false, italic: null,
    underlinePresent: false, underline: null,
    highlightColorPresent: false, highlightColor: null,
    familyNamePresent: false, familyName: null, fontSizePresent: false, fontSize: null,
    foregroundColorPresent: false, foregroundColor: null, linkPresent: false, link: null,
    superscriptPresent: false, superscript: null, subscriptPresent: false, subscript: null,
    strikethroughPresent: false, strikethrough: null,
    indentLevelPresent: false, indentLevel: null, alignmentPresent: false, alignment: null,
    lineSpacingPresent: false, lineSpacing: null,
    decoratorStylePresent: false, decoratorStyle: null,
    programmingLanguagePresent: false, programmingLanguage: null,
    writingDirectionPresent: false, writingDirection: null,
  };
}

function readBoundaryRow(rows: relationalStore.ResultSet, prefix: string): OriginalTextBoundary {
  const location: OriginalSequenceIdentity = {
    timestamp: rows.getLong(rows.getColumnIndex(`${prefix}_timestamp`)),
    siteId: rows.getLong(rows.getColumnIndex(`${prefix}_site_id`)),
    index: rows.getLong(rows.getColumnIndex(`${prefix}_index`)),
  };
  validateOriginalSequenceIdentity(location);
  const type: number = rows.getLong(rows.getColumnIndex(`${prefix}_type`));
  if (type < OriginalTextBoundaryType.BEFORE || type > OriginalTextBoundaryType.END_OF_DOC) {
    throw new Error('original text style boundary type is invalid');
  }
  return { location: location, type: type as OriginalTextBoundaryType };
}

function orderCharacters(characters: StoredOriginalTextCharacter[]): StoredOriginalTextCharacter[] | null {
  const byId: Map<string, StoredOriginalTextCharacter> = new Map();
  const children: Map<string, StoredOriginalTextCharacter[]> = new Map();
  for (const character of characters) {
    const key: string = encodeOriginalSequenceId(character.identity);
    if (byId.has(key)) {
      return null;
    }
    byId.set(key, character);
  }
  for (const character of characters) {
    const parentKey: string = character.parent === null ? '' :
      encodeOriginalSequenceId(character.parent);
    if (character.parent !== null && !byId.has(parentKey)) {
      return null;
    }
    const siblings: StoredOriginalTextCharacter[] = children.get(parentKey) ?? [];
    siblings.push(character);
    children.set(parentKey, siblings);
  }
  for (const siblings of children.values()) {
    siblings.sort((left: StoredOriginalTextCharacter,
      right: StoredOriginalTextCharacter): number =>
      -compareOriginalSequenceIdentity(left.identity, right.identity));
  }
  const result: StoredOriginalTextCharacter[] = [];
  const stack: StoredOriginalTextCharacter[] = (children.get('') ?? []).slice().reverse();
  while (stack.length > 0) {
    const current: StoredOriginalTextCharacter = stack.pop() as StoredOriginalTextCharacter;
    result.push(current);
    const descendants: StoredOriginalTextCharacter[] = children.get(
      encodeOriginalSequenceId(current.identity)) ?? [];
    for (let index: number = descendants.length - 1; index >= 0; index--) {
      stack.push(descendants[index]);
    }
  }
  return result.length === characters.length ? result : null;
}

function resolveRange(operation: StoredOriginalTextStyleOperation,
  positions: Map<string, number>, length: number): number[] | null {
  const start: number | null = boundaryPosition(operation.start, positions, length);
  const end: number | null = boundaryPosition(operation.end, positions, length);
  if (start === null || end === null || start > end) {
    return null;
  }
  return [start, end];
}

function boundaryPosition(boundary: OriginalTextBoundary,
  positions: Map<string, number>, length: number): number | null {
  if (boundary.type === OriginalTextBoundaryType.START_OF_DOC) {
    return 0;
  }
  if (boundary.type === OriginalTextBoundaryType.END_OF_DOC) {
    return length;
  }
  if (boundary.location.timestamp === 0 && boundary.location.siteId === 0xFFFF &&
    boundary.location.index === 0) {
    return boundary.type === OriginalTextBoundaryType.BEFORE ? 0 : null;
  }
  const position: number | undefined = positions.get(encodeOriginalSequenceId(boundary.location));
  if (position === undefined) {
    return null;
  }
  return boundary.type === OriginalTextBoundaryType.AFTER ? position + 1 : position;
}

function appendCharacterRun(runs: RichTextCharacterStyleRun[], index: number,
  style: RichTextCharacterStyle): void {
  if (Object.keys(style).length === 0) {
    return;
  }
  const previous: RichTextCharacterStyleRun | undefined = runs[runs.length - 1];
  if (previous !== undefined && previous.end === index &&
    JSON.stringify(previous.style) === JSON.stringify(style)) {
    previous.end++;
  } else {
    runs.push({ start: index, end: index + 1, style: style });
  }
}

function appendParagraphRun(runs: RichTextParagraphStyleRun[], index: number,
  style: RichTextParagraphStyle): void {
  if (Object.keys(style).length === 0) {
    return;
  }
  const previous: RichTextParagraphStyleRun | undefined = runs[runs.length - 1];
  if (previous !== undefined && previous.end === index &&
    JSON.stringify(previous.style) === JSON.stringify(style)) {
    previous.end++;
  } else {
    runs.push({ start: index, end: index + 1, style: style });
  }
}

function applyCharacterAttributes(style: RichTextCharacterStyle,
  attributes: OriginalTextStyleAttributes): RichTextCharacterStyle {
  const updated: RichTextCharacterStyle = {};
  if (attributes.boldPresent ? attributes.bold !== null : style.bold !== undefined) {
    updated.bold = attributes.boldPresent ? attributes.bold as boolean : style.bold;
  }
  if (attributes.italicPresent ? attributes.italic !== null : style.italic !== undefined) {
    updated.italic = attributes.italicPresent ? attributes.italic as boolean : style.italic;
  }
  if (attributes.underlinePresent ? attributes.underline !== null : style.underline !== undefined) {
    updated.underline = attributes.underlinePresent ? attributes.underline as boolean : style.underline;
  }
  if (attributes.highlightColorPresent ? attributes.highlightColor !== null :
    style.highlightColor !== undefined) {
    updated.highlightColor = attributes.highlightColorPresent ?
      attributes.highlightColor as number : style.highlightColor;
  }
  if (attributes.familyNamePresent ? attributes.familyName !== null : style.familyName !== undefined) {
    updated.familyName = attributes.familyNamePresent ? attributes.familyName as string : style.familyName;
  }
  if (attributes.fontSizePresent ? attributes.fontSize !== null : style.fontSize !== undefined) {
    updated.fontSize = attributes.fontSizePresent ? attributes.fontSize as number : style.fontSize;
  }
  if (attributes.foregroundColorPresent ? attributes.foregroundColor !== null :
    style.foregroundColor !== undefined) {
    updated.foregroundColor = attributes.foregroundColorPresent ?
      attributes.foregroundColor as number : style.foregroundColor;
  }
  if (attributes.linkPresent ? attributes.link !== null : style.link !== undefined) {
    updated.link = attributes.linkPresent ? attributes.link as string : style.link;
  }
  if (attributes.superscriptPresent ? attributes.superscript !== null :
    style.superscript !== undefined) {
    updated.superscript = attributes.superscriptPresent ?
      attributes.superscript as boolean : style.superscript;
  }
  if (attributes.subscriptPresent ? attributes.subscript !== null : style.subscript !== undefined) {
    updated.subscript = attributes.subscriptPresent ? attributes.subscript as boolean : style.subscript;
  }
  if (attributes.strikethroughPresent ? attributes.strikethrough !== null :
    style.strikethrough !== undefined) {
    updated.strikethrough = attributes.strikethroughPresent ?
      attributes.strikethrough as boolean : style.strikethrough;
  }
  return updated;
}

function applyParagraphAttributes(style: RichTextParagraphStyle,
  attributes: OriginalTextStyleAttributes): RichTextParagraphStyle {
  const updated: RichTextParagraphStyle = {};
  if (attributes.indentLevelPresent ? attributes.indentLevel !== null :
    style.indentLevel !== undefined) {
    updated.indentLevel = attributes.indentLevelPresent ?
      attributes.indentLevel as number : style.indentLevel;
  }
  if (attributes.alignmentPresent ? attributes.alignment !== null : style.alignment !== undefined) {
    updated.alignment = attributes.alignmentPresent ? attributes.alignment as number : style.alignment;
  }
  if (attributes.lineSpacingPresent ? attributes.lineSpacing !== null :
    style.lineSpacing !== undefined) {
    updated.lineSpacing = attributes.lineSpacingPresent ?
      attributes.lineSpacing as number : style.lineSpacing;
  }
  if (attributes.decoratorStylePresent ? attributes.decoratorStyle !== null :
    style.decoratorStyle !== undefined) {
    updated.decoratorStyle = attributes.decoratorStylePresent ?
      attributes.decoratorStyle as number : style.decoratorStyle;
  }
  if (attributes.programmingLanguagePresent ? attributes.programmingLanguage !== null :
    style.programmingLanguage !== undefined) {
    updated.programmingLanguage = attributes.programmingLanguagePresent ?
      attributes.programmingLanguage as string : style.programmingLanguage;
  }
  if (attributes.writingDirectionPresent ? attributes.writingDirection !== null :
    style.writingDirection !== undefined) {
    updated.writingDirection = attributes.writingDirectionPresent ?
      attributes.writingDirection as number : style.writingDirection;
  }
  if (style.isChecked !== undefined) {
    updated.isChecked = style.isChecked;
  }
  return updated;
}

function validateAttributes(attributes: OriginalTextStyleAttributes,
  paragraph: boolean, clearAll: boolean): boolean {
  if (attributes === null || typeof attributes !== 'object') {
    return false;
  }
  if (!allPresenceFlagsAreBoolean(attributes) ||
    !isNullableBoolean(attributes.bold) || !isNullableBoolean(attributes.italic) ||
    !isNullableBoolean(attributes.underline) || !isNullableBoolean(attributes.superscript) ||
    !isNullableBoolean(attributes.subscript) || !isNullableBoolean(attributes.strikethrough) ||
    !isNullableColor(attributes.highlightColor) || !isNullableColor(attributes.foregroundColor) ||
    !isNullableString(attributes.familyName) || !isNullableString(attributes.link) ||
    !isNullableString(attributes.programmingLanguage) || !isNullableFinite(attributes.fontSize) ||
    !isNullableIntegerRange(attributes.indentLevel, 0, 7) ||
    !isNullableIntegerRange(attributes.alignment, 1, 3) ||
    !isNullableFinite(attributes.lineSpacing) ||
    !isNullableIntegerRange(attributes.decoratorStyle, 0, 5) ||
    !isNullableIntegerRange(attributes.writingDirection, 0, 1)) {
    return false;
  }
  if (attributes.familyNamePresent && attributes.familyName !== null && attributes.familyName.length === 0) {
    return false;
  }
  if (attributes.fontSizePresent && attributes.fontSize !== null && attributes.fontSize <= 0) {
    return false;
  }
  if (attributes.superscript === true && attributes.subscript === true) {
    return false;
  }
  if (clearAll) {
    return true;
  }
  const hasCharacter: boolean = attributes.boldPresent || attributes.italicPresent ||
    attributes.underlinePresent || attributes.highlightColorPresent || attributes.familyNamePresent ||
    attributes.fontSizePresent || attributes.foregroundColorPresent || attributes.linkPresent ||
    attributes.superscriptPresent || attributes.subscriptPresent || attributes.strikethroughPresent;
  const hasParagraph: boolean = attributes.indentLevelPresent || attributes.alignmentPresent ||
    attributes.lineSpacingPresent || attributes.decoratorStylePresent ||
    attributes.programmingLanguagePresent || attributes.writingDirectionPresent;
  return paragraph ? hasParagraph && !hasCharacter : hasCharacter && !hasParagraph;
}

function allPresenceFlagsAreBoolean(attributes: OriginalTextStyleAttributes): boolean {
  return typeof attributes.boldPresent === 'boolean' &&
    typeof attributes.italicPresent === 'boolean' &&
    typeof attributes.underlinePresent === 'boolean' &&
    typeof attributes.highlightColorPresent === 'boolean' &&
    typeof attributes.familyNamePresent === 'boolean' &&
    typeof attributes.fontSizePresent === 'boolean' &&
    typeof attributes.foregroundColorPresent === 'boolean' &&
    typeof attributes.linkPresent === 'boolean' &&
    typeof attributes.superscriptPresent === 'boolean' &&
    typeof attributes.subscriptPresent === 'boolean' &&
    typeof attributes.strikethroughPresent === 'boolean' &&
    typeof attributes.indentLevelPresent === 'boolean' &&
    typeof attributes.alignmentPresent === 'boolean' &&
    typeof attributes.lineSpacingPresent === 'boolean' &&
    typeof attributes.decoratorStylePresent === 'boolean' &&
    typeof attributes.programmingLanguagePresent === 'boolean' &&
    typeof attributes.writingDirectionPresent === 'boolean';
}

function isNullableBoolean(value: boolean | null): boolean {
  return value === null || typeof value === 'boolean';
}

function isNullableString(value: string | null): boolean {
  return value === null || (typeof value === 'string' && value.length <= 65536);
}

function isNullableColor(value: number | null): boolean {
  return value === null || (Number.isSafeInteger(value) &&
    value >= -2147483648 && value <= 4294967295);
}

function isNullableFinite(value: number | null): boolean {
  return value === null || (typeof value === 'number' && Number.isFinite(value));
}

function isNullableIntegerRange(value: number | null, minimum: number, maximum: number): boolean {
  return value === null || (Number.isSafeInteger(value) && value >= minimum && value <= maximum);
}
