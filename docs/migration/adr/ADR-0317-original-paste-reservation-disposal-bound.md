# ADR-0317: Original paste reservation disposal bound

- Date: 2026-08-23
- Status: Accepted
- Scope: Harmony editor clipboard Original Ink identity reservation

## Context

`pasteClipboard()` captures `pageLoadGeneration` and `loadedPageId`, sets `historyBusy`, and awaits `reserveOriginalInkCreate()`. Its success callback checked generation/page/loading flags but not editor lifecycle; its failure path unconditionally called the save-failure UI. A page could leave during the async reservation and a late result could mutate or publish to stale UI context.

## Decision

- Route success through `isHistoryPageContextCurrent(generation, pageId)`, which includes `lifecycleActive`.
- Publish reservation failures only when the same lifecycle/page context is still current.
- Log stale failures without save-failure publication.
- Keep `.finally()` unconditional so `historyBusy` cannot remain set for the next page.

## Consequences

Stale reservations can no longer apply clipboard content or surface errors on a disposed/stale editor. The durable identity reservation remains authoritative and harmless; real paste UX races remain device acceptance work. No emulator, device, virtual machine, or Hypium is started.
