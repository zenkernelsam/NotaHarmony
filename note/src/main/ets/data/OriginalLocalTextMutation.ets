import { OriginalSequenceIdentity } from './OperationIdentity';
import {
  materializeOriginalTextCharacterOrder, StoredCharacter,
} from './OriginalInsertTextOperation';

export interface OriginalLocalTextMutationPlan {
  removed: OriginalSequenceIdentity[];
  revived: OriginalSequenceIdentity[];
  insertedScalars: number[];
  insertionLocation: OriginalSequenceIdentity | null;
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
