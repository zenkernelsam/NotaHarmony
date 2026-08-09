export function importedLegacyNoteId(sourceNoteId: string, targetNoteId: string): string | null {
  if (sourceNoteId.length === 0 || targetNoteId.length === 0) {
    throw new Error('import identity requires source and target note IDs');
  }
  return sourceNoteId === targetNoteId ? null : sourceNoteId;
}

export function importedPageNeedsRemap(isNoteCopy: boolean, locallyOccupied: boolean,
  alreadyAssigned: boolean): boolean {
  return isNoteCopy || locallyOccupied || alreadyAssigned;
}
