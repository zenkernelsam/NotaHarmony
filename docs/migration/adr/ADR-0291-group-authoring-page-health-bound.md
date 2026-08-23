# ADR-0291: Bind Group Authoring Results to Page Health

Date: 2026-08-23

## Context

Group/Ungroup authoring calls createOriginalGroup() and ungroupOriginalGroup(), which perform
durable SQLite transactions and can cross page navigation. The success paths used weak guards
comparing only pageLoadGeneration, loadedPageId, and currentPage.pageId. If the same page
reloaded (same ID, new generation) or entered a loading/failure state, a late result could
mutate the wrong visible state.

## Decision

Replace all four guards (Group success/catch, Ungroup success/catch) with
isHistoryPageContextCurrent(generation, pageId), which additionally requires lifecycle active,
loaded, not loading, and not load-failed. Durable SQLite commits remain authoritative; stale
successes still push to undo history but skip local array/selection/layer/render/eligibility
mutations. Stale failures log but do not call reportSaveFailure() on the current page.

## Consequences

Late Group/Ungroup results cannot corrupt a freshly reloaded or unhealthy page. The durable
undo history entry remains available for the correct page. Real device navigation stress
testing is still required.
