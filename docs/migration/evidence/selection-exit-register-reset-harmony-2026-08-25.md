# Evidence: Selection exit register reset

Date: 2026-08-25 (Asia/Shanghai)

## Source review

- `NoteCanvasView` had only one successful page-switch path that paired `deselect()` with
  `(null, null, 0.5, 30, true, null)`.
- Eleven authoritative exits cleared `SelectionTool` but left the page registers:
  load failure, cancel interaction while selecting/dragging, partial-erase completion,
  four durable history branches, generic history apply, DELETE/CUT, DESELECT, and math insert.
- The stale values are not display-only: `NotePage.selectionInkColor/Width/Style` also feed later
  selection style/color/width signals.

## Reverse-engineering comparison

- Original 1.0.3 `xsc.m()/s()/t()` resets selection state to an empty context atomically.
- Therefore every authoritative exit must clear both selection identity and command-source registers;
  temporary UI transitions that preserve conceptual selection must not.

## Change

- Added `clearSelectionWithRegisterReset()` as the single deselect/reset publication helper.
- Converted all eleven authoritative exits from separate deselect/hide pairs to this helper.
- Kept drawing start and editor/crop transitions unchanged because they do not authoritatively end selection.

## Verification

* Focused Replay strengthened with helper-order assertions for all eleven exits and a register-state
  reset simulation covering color, width, style, and Taper eligibility.
* Focused Replay passes; full Desktop Replay passed 371/371.
* ArkTS diagnostics for `NoteCanvasView.ets`, `NotePage.ets`, and `EditorToolbar.ets` contain no errors.
* Clean plus dual static HAP builds succeeded (clean 28.804s, ohosTest 32.356s, default 3.821s).
* No emulator, VM, device, or Hypium was started.
