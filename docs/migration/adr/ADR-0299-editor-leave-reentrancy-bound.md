# ADR-0299: Bind Editor Leave Flow to a Single Reentrancy Guard

Date: 2026-08-23

## Context

`leaveEditor()` awaited the title save queue, page history flush, tool-state flush, recording delete flush, session finish, and playback release before calling `router.back()`. The back button and Android-compatible back press could each start this flow independently, so two concurrent invocations could both reach `router.back()` and pop an extra library route.

## Decision

Wrap `performLeaveEditor()` behind `leaveEditor()` with a shared `editorLeavePromise`. The first caller owns the full teardown sequence; later callers await and return the same promise. The sequence itself remains unchanged.

## Consequences

Rapid duplicate back actions cannot create competing editor teardowns or repeated navigation. A failed leave still resolves its shared promise without resetting the guard, preserving one-shot navigation semantics for this editor instance.
