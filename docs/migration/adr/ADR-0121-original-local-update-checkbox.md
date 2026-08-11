# ADR-0121: Produce original UpdateCheckbox for local checkbox state changes

## Status

Accepted, 2026-08-12.

## Evidence

- Original `fm7.n(index)` invokes the editor bridge action `toggleCheckbox`. `wh` resolves that
  document block, requires `fy2.CHECK_BOX`, maps its code-point start through `t3c.w(index)` to a
  stable RichText location and negates the current checked value.
- `gv0.o()` submits the resolved location and boolean through `u5j.J()`. That writer creates `mqf`
  with TextField in field 0, stable location in field 1 and checked boolean in field 2.
- False is the FlatBuffer default. The original writer may omit field 2 while still representing an
  explicit unchecked update.
- The existing Harmony reducer and database register already implement inbound type-28 authority;
  falling back to a generic page snapshot for a local toggle would bypass that CRDT and private sync.

## Decision

- Add a production type-28 encoder with strict TextField/location validation and canonical omitted
  false encoding.
- Add a pure local checkbox planner. It accepts exactly one CHECK_BOX paragraph-start toggle,
  operates in Unicode code-point space, maps the visible character to its persisted SeqId and
  rejects text/style/geometry changes or non-canonical sources.
- In the normal save and grouped Undo/Redo pipelines, classify this mutation before normal text
  edits. Re-read character/style/checkbox authority and require the editor's before snapshot to
  match reducer materialization before writing.
- Apply the encoded payload through `OriginalUpdateCheckboxOperationApplier`, require the reducer's
  page snapshot to equal the requested after state, append an upload-immediate original operation
  and retain the normal history page-mutation companion.
- Register `ORIGINAL_UPDATE_CHECKBOX` as an outbound history companion so reload preserves action
  boundaries without treating the private-sync row as a legacy break.

## Rejected Alternatives

- Mutate only `paragraphStyleRuns`: checked state is an independent CRDT register, not type-13 data.
- Encode character offsets directly: the original resolves a stable `exc`/SeqId location so edits
  before the checkbox do not retarget the update.
- Accept any `isChecked` diff: original interaction only toggles a CHECK_BOX document block at its
  paragraph start; looser matching could serialize corrupt or unrelated style edits as type-28.
- Add touch hit testing in this phase: layout hit regions need a separate renderer/UI contract and
  device acceptance, while the protocol/persistence path can be proven independently.

## Verification

- `OriginalLocalCheckboxMutation.test.ets` covers both toggle directions, paragraph-start gating,
  Unicode code-point to SeqId mapping, source immutability, changed-text rejection and true/omitted
  false payload round trips.
- `d02-local-update-checkbox.mjs` locks the original bridge/writer chain and Harmony classification,
  authority, upload and history contracts. The existing inbound replay also checks the new encoder.
- Full replay and clean HAP results are recorded in the Phase 144 report. No device is used.

## Remaining Boundary

The data and history path is ready for an editor interaction, but the current Harmony TextArea does
not expose original list-marker hit regions. A following phase must add renderer-consistent checkbox
hit testing and route the successful toggle into the existing REPLACE_ELEMENT Undo/Redo workflow.
