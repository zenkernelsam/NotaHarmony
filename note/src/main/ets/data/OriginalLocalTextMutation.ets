import {
  nextOperationTimestamp, OperationIdentity, OriginalSequenceIdentity, validateOperationIdentity,
} from './OperationIdentity';
import {
  RichTextCharacterStyleRun, RichTextParagraphStyleRun,
} from '../core/model/ElementTypes';
import {
  materializeCharacters, materializeOriginalTextCharacterOrder, StoredCharacter,
} from './OriginalInsertTextOperation';
import {
  materializeOriginalTextStyles, StoredOriginalCheckboxState,
  StoredOriginalTextStyleOperation,
} from './OriginalRichTextStyleState';

export interface OriginalLocalTextMutationPlan {
  removed: OriginalSequenceIdentity[];
  revived: OriginalSequenceIdentity[];
  insertedScalars: number[];
  insertionLocation: OriginalSequenceIdentity | null;
}

export interface OriginalLocalTextMutationPreview {
  plan: OriginalLocalTextMutationPlan;
  characterStyleRuns: RichTextCharacterStyleRun[];
  paragraphStyleRuns: RichTextParagraphStyleRun[];
}

export function predictOriginalTextInsertionIdentity(maxTimestamp: number, siteId: number,
  plan: OriginalLocalTextMutationPlan): OperationIdentity | null {
  if (plan.insertedScalars.length === 0) {
    return null;
  }
  try {
    validateOperationIdentity({ timestamp: maxTimestamp, siteId: siteId });
    let timestamp: number = maxTimestamp;
    if (plan.removed.length > 0) {
      timestamp = nextOperationTimestamp(timestamp);
    }
    if (plan.revived.length > 0) {
      timestamp = nextOperationTimestamp(timestamp);
    }
    timestamp = nextOperationTimestamp(timestamp);
    return { timestamp: timestamp, siteId: siteId };
  } catch (_error) {
    return null;
  }
}

export function previewOriginalLocalTextMutation(characters: StoredCharacter[],
  styleOperations: StoredOriginalTextStyleOperation[], checkboxStates: StoredOriginalCheckboxState[],
  before: string, after: string, insertionIdentity: OperationIdentity | null):
  OriginalLocalTextMutationPreview | null {
  const plan: OriginalLocalTextMutationPlan | null =
    planOriginalLocalTextMutation(characters, before, after);
  if (plan === null || (plan.insertedScalars.length > 0) !== (insertionIdentity !== null)) {
    return null;
  }
  if (insertionIdentity !== null) {
    try {
      validateOperationIdentity(insertionIdentity);
    } catch (_error) {
      return null;
    }
  }
  const simulated: StoredCharacter[] = characters.map(
    (character: StoredCharacter): StoredCharacter => cloneCharacter(character));
  const byId: Map<string, StoredCharacter> = new Map<string, StoredCharacter>();
  for (const character of simulated) {
    byId.set(identityKey(character.identity), character);
  }
  for (const identity of plan.removed) {
    const character: StoredCharacter | undefined = byId.get(identityKey(identity));
    if (character === undefined) {
      return null;
    }
    character.visible = false;
  }
  for (const identity of plan.revived) {
    const character: StoredCharacter | undefined = byId.get(identityKey(identity));
    if (character === undefined) {
      return null;
    }
    character.visible = true;
  }
  if (insertionIdentity !== null) {
    let parent: OriginalSequenceIdentity | null = plan.insertionLocation === null ? null :
      cloneIdentity(plan.insertionLocation);
    for (let index: number = 0; index < plan.insertedScalars.length; index++) {
      const identity: OriginalSequenceIdentity = {
        timestamp: insertionIdentity.timestamp, siteId: insertionIdentity.siteId, index: index,
      };
      simulated.push({
        identity: identity, parent: parent, scalar: plan.insertedScalars[index], visible: true,
        visibilityWinner: null,
      });
      parent = identity;
    }
  }
  if (materializeCharacters(simulated) !== after) {
    return null;
  }
  const styles = materializeOriginalTextStyles(simulated, styleOperations, checkboxStates);
  return styles === null ? null : {
    plan: plan, characterStyleRuns: styles.characterRuns,
    paragraphStyleRuns: styles.paragraphRuns,
  };
}

export function planOriginalLocalTextMutation(characters: StoredCharacter[],
  before: string, after: string): OriginalLocalTextMutationPlan | null {
  const beforeScalars: number[] | null = strictScalars(before);
  const afterScalars: number[] | null = strictScalars(after);
  const ordered: StoredCharacter[] | null = materializeOriginalTextCharacterOrder(characters);
  if (beforeScalars === null || afterScalars === null || ordered === null || before === after) {
    return null;
  }
  const visible: StoredCharacter[] = ordered.filter(
    (character: StoredCharacter): boolean => character.visible);
  if (!sameScalars(visible.map((character: StoredCharacter): number => character.scalar),
    beforeScalars)) {
    return null;
  }
  let prefix: number = 0;
  while (prefix < beforeScalars.length && prefix < afterScalars.length &&
    beforeScalars[prefix] === afterScalars[prefix]) {
    prefix++;
  }
  let suffix: number = 0;
  while (suffix < beforeScalars.length - prefix && suffix < afterScalars.length - prefix &&
    beforeScalars[beforeScalars.length - 1 - suffix] ===
      afterScalars[afterScalars.length - 1 - suffix]) {
    suffix++;
  }
  const removedCharacters: StoredCharacter[] = visible.slice(
    prefix, beforeScalars.length - suffix);
  const insertedScalars: number[] = afterScalars.slice(prefix, afterScalars.length - suffix);
  const removed: OriginalSequenceIdentity[] = removedCharacters.map(
    (character: StoredCharacter): OriginalSequenceIdentity => cloneIdentity(character.identity));
  const insertionLocation: OriginalSequenceIdentity | null = prefix === 0 ? null :
    cloneIdentity(visible[prefix - 1].identity);
  const revived: OriginalSequenceIdentity[] = findReviveCandidate(
    ordered, removedCharacters, insertedScalars, afterScalars, prefix);
  return {
    removed: removed,
    revived: revived,
    insertedScalars: revived.length === 0 ? insertedScalars : [],
    insertionLocation: insertionLocation,
  };
}

function findReviveCandidate(ordered: StoredCharacter[], removed: StoredCharacter[],
  insertedScalars: number[], expected: number[], prefix: number): OriginalSequenceIdentity[] {
  if (insertedScalars.length === 0) {
    return [];
  }
  const removedKeys: Set<string> = new Set<string>();
  for (const character of removed) {
    removedKeys.add(identityKey(character.identity));
  }
  const candidate: StoredCharacter[] = [];
  let retainedCount: number = 0;
  let scalarIndex: number = 0;
  for (const character of ordered) {
    const key: string = identityKey(character.identity);
    if (character.visible && !removedKeys.has(key)) {
      retainedCount++;
      continue;
    }
    if (!character.visible && retainedCount === prefix &&
      scalarIndex < insertedScalars.length && character.scalar === insertedScalars[scalarIndex]) {
      candidate.push(character);
      scalarIndex++;
    }
  }
  if (scalarIndex !== insertedScalars.length) {
    return [];
  }
  const revivedKeys: Set<string> = new Set<string>();
  for (const character of candidate) {
    revivedKeys.add(identityKey(character.identity));
  }
  const materialized: number[] = [];
  for (const character of ordered) {
    const key: string = identityKey(character.identity);
    if ((character.visible && !removedKeys.has(key)) || revivedKeys.has(key)) {
      materialized.push(character.scalar);
    }
  }
  if (sameScalars(materialized, expected)) {
    return candidate.map((character: StoredCharacter): OriginalSequenceIdentity =>
      cloneIdentity(character.identity));
  }
  return [];
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

function sameScalars(left: number[], right: number[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (left[index] !== right[index]) {
      return false;
    }
  }
  return true;
}

function identityKey(identity: OriginalSequenceIdentity): string {
  return `${identity.timestamp}:${identity.siteId}:${identity.index}`;
}

function cloneIdentity(identity: OriginalSequenceIdentity): OriginalSequenceIdentity {
  return { timestamp: identity.timestamp, siteId: identity.siteId, index: identity.index };
}

function cloneCharacter(character: StoredCharacter): StoredCharacter {
  return {
    identity: cloneIdentity(character.identity),
    parent: character.parent === null ? null : cloneIdentity(character.parent),
    scalar: character.scalar, visible: character.visible,
    visibilityWinner: character.visibilityWinner === null ? null : {
      timestamp: character.visibilityWinner.timestamp, siteId: character.visibilityWinner.siteId,
    },
  };
}
