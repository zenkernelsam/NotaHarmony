# Evidence: Selection replacement register reset

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- Post-Phase-418 audit found replacement paths that install a new `selectElementIds()` result after the old
  identity is cleared: original photo insert, Math insert, Group, Ungroup, paste, and image crop cancel/confirm.
- If the prior selection was ink and the new selection was shape/image/math/group-only, the old
  NotePage.selectionInkColor/Width/Style survived the identity change. The toolbar could show and dispatch the
  previous context even though no eligible ink was selected.

## Reverse-engineering comparison

- Original 1.0.3 builds each style popover from the current selected entity set (`dhb` derives color, width,
  and style before showing controls) rather than retaining a prior popover register across a different selection.

## Change

- Added explicit nullable-register resets to all nine replacement sites after installing the new IDs.
- Made `updateSelectionOverlay()` hide empty selections without publishing a reset; temporary empty-state calls
  therefore cannot overwrite an authoritative exit's default state.
- Kept drag restore unchanged because it restores the same conceptual selection.

## Verification

* Focused Replay strengthened with empty-overlay ordering, at least eleven explicit reset sites, and all major
  replacement contexts. It passes.
* Full Desktop Replay passed 371/371; ArkTS diagnostics for touched editor files had no errors.
* Clean plus dual static HAP builds succeeded (clean 28.804s, ohosTest 29.296s, default 3.459s).
  No emulator, VM, device, or Hypium was started.
