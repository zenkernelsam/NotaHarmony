# ADR-0664: Original page-selection count label + `default_note_title` resource parity

- **Status**: Accepted
- **Phase**: 716
- **Depends on**: ADR-0615 (page-selection toolbar), ADR-0629 (import details sheet)

## Context

Two small `ui_pageselection__`/`data_library_state__` parity gaps found
while sweeping remaining string families:

1. `ui_pageselection__x_of_y_selected` — the original `tfh` page
   selection toolbar renders "N of M selected" (`p7j.java:663`/`951`,
   `tl7.T(..., selected, list.size())`) beside the action buttons.
   Harmony's toolbar had select/deselect-all + batch ops but no count.
2. `data_library_state__default_note_title` — original default title is
   the resource string "New Note" (`id7.java:1172` creation default,
   `bib.java:43` library fallback). Harmony had the correct
   `untitled_note` = "New Note" resource, but `ImportDetailsSheet`
   hardcoded a `'Untitled'` literal — wrong text and non-localizable.
   (`ui_pageselection__no_pages` was already ported as
   `pages_panel_empty`; `select_all`/`deselect_all` exist.)

## Decision

1. `PageOverviewPanel` selection toolbar: fixed count label
   `$r('app.string.pages_x_of_y_selected', selected, visible)` ahead of
   the scrolling action chips (`layoutWeight(1)` keeps chip scroll);
   denominator = `visibleItems()` (the filtered list), matching
   `list.size()` at `p7j`.
2. `ImportDetailsSheet`: `'Untitled'` literal →
   `$r('app.string.untitled_note')` — same "New Note" resource the rest
   of the app uses.
3. New strings `pages_x_of_y_selected`: en `%d of %d selected`
   (sequential `%d` per existing `share_range_selected` convention),
   zh `已选 %d/%d 页`.

## Consequences

- Selection toolbar shows the running count; no layout regression —
  chips still scroll horizontally.
- All default-note-title surfaces now share one localizable resource
  matching the original "New Note".
