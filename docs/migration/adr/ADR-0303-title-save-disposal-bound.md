# ADR-0303: Bind Title Save Completion to Editor Disposal

Date: 2026-08-23

## Context

`commitTitle()` awaited `updateNoteTitle()` without checking whether the editor was still alive. A rapid back action during the durable write could let the stale continuation overwrite `noteTitle`, publish `titleDraft`, mutate history, or show a save-failure toast against the disposed page.

## Decision

Set `editorDisposed` in `aboutToDisappear()`. After the title persistence await and in the catch path, skip all memory publication, history mutation, and UI feedback when the editor is disposed. The durable title result remains authoritative.

## Consequences

Late title save success or failure cannot mutate disposed state or show feedback. The next editor instance loads the materialized title from durable data normally.
