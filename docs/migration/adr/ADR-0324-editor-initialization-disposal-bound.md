# ADR-0324: Editor initialization disposal bound

- Date: 2026-08-24
- Status: Accepted
- Scope: Harmony editor initial page-load failure publication

## Context

`loadPages()` guarded its failure path with the page-load generation, but not `editorDisposed`. Initialization could fail after the editor was disposed; the late continuation then reset page/background/recording state, marked `pageLoadFailed`, and showed an open-failure toast on a removed page.

## Decision

- Treat disposal as stale in addition to generation change.
- A failed initialization continuation returns immediately when `editorDisposed` is true, without state resets or user-visible error UI.
- Keep durable initialization effects authoritative and preserve existing success-path lifecycle behavior.

## Consequences

A removed editor can no longer publish late initialization errors. The next editor instance starts fresh and reports its own load result. No device or Hypium runtime is required to verify this static lifecycle boundary.