# Original page-selection count + default note title — JADX evidence (2026-09-26)

## `ui_pageselection__x_of_y_selected`

`strings.xml`: `"%1$d of %2$d selected"`.

`p7j.java:663` and `p7j.java:951` (two toolbar variants):

```java
String strT = tl7.T(R.string.ui_pageselection__x_of_y_selected,
    new Object[]{Integer.valueOf(i10), Integer.valueOf(list.size())}, uz4Var);
tpe.b(strT, pd8VarC3 /* padding 16h */, ..., are.K, uz4Var, 0, 0, 131068);
```

Rendered inside the page-selection toolbar row after the action button —
`i10` = selected count, `list.size()` = the (filtered) page list.

(`ui_pageselection__no_pages` → Harmony `pages_panel_empty`,
`select_all`/`deselect_all` → `pages_select_all`/`pages_deselect_all`
were already ported in the `tfh` toolbar phases.)

## `data_library_state__default_note_title` = "New Note"

`strings.xml`: `"New Note"`. Consumers:

- `id7.java:1172` — `getString(...)` as the creation-time default title.
- `bib.java:43` — library row title fallback (`strL != null ? gvd(strL)
  : bxb(default_note_title)`).
- `e5j.java:325`, `ksh.java:935` — note-title display fallbacks.

Harmony already owns the equivalent resource `untitled_note` = "New Note"
(zh "新笔记") used by `NotePage`/`RecentlyDeletedPage`; Phase 716 fixes
the one stray literal in `ImportDetailsSheet` ("Untitled" → resource).

## `ui_composeutil__error_unable_to_open_link`

`cq.java:2322/2362/2403` — toast on failed link open. Harmony link-open
failures already toast via `link_open_failed` (existing coverage) — no
gap; noted here for family completeness.
