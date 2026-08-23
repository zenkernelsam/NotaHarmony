# ADR-0300: Bind NotePage Initial Load to Page Lifecycle

Date: 2026-08-23

## Context

`loadPages()` awaited database initialization, tool settings, note metadata, page list, optional zero-page recovery, background loading, and recording loading without checking whether the editor was still alive. Rapid open-and-close could let the stale continuation mutate disposed state, create a fallback page for an already-closed note, or show a failure toast after disposal.

## Decision

Add `pageLoadGeneration`, increment it in `aboutToDisappear()` and at each load start, and check it after note metadata, after page materialization, in the catch handler, and before finally-state resets. Stale continuations return immediately without touching state, creating recovery pages, or showing UI.

## Consequences

A disposed editor's late load cannot publish pages, titles, backgrounds, recordings, or error feedback. Durable data remains authoritative; a subsequent editor instance starts its own generation and loads normally.
