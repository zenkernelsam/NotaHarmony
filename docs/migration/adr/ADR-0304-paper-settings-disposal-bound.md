# ADR-0304: Bind Paper Settings Mutations to Panel Disposal

Date: 2026-08-23

## Context

`toggleFavorite()` and `saveSharedSpacing()` awaited durable store operations without checking whether the settings panel was still alive. If the user closed the panel during SQLite work, the stale continuation could overwrite `favorites`, replace background infos, mutate preview state, or show a failure toast against the disposed component.

## Decision

Set `panelDisposed` in `aboutToDisappear()`. After each durable await and in catch paths, skip all memory publication and UI feedback when disposed. Durable favorite/spacing results remain authoritative.

## Consequences

Late favorite toggles and spacing saves cannot mutate a disposed panel or show feedback. The next panel instance loads authoritative shared settings normally.
