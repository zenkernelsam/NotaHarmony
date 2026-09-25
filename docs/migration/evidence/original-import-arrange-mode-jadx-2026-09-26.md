# Original import-sheet arrange mode — JADX evidence (2026-09-26)

Phase 715 evidence for the arrange mode inside `zvh.a` (import details
sheet, ADR-0629).

## Strings

`resources/res/values/strings.xml`:

- `ui_fileimport__arrange` — "Arrange"
- `ui_fileimport__done` — "Done"
- `ui_fileimport__move_up` — "Move up"
- `ui_fileimport__move_down` — "Move down"

## Toggle — `w8.java` case 6 (line ~155)

```java
v3j.a(null, tl7.U(uz4Var3, z11 ? R.string.ui_fileimport__done
    : R.string.ui_fileimport__arrange), null, false, false, null,
    zp8.J, wp8.L, null, 0L,
    z11 ? function0 : function1, ...);
```

A single header button whose label flips Arrange↔Done on `z11`
(arranging) and invokes the matching enter/exit callback.

## Row moves — `te4.java` (lines ~76-77)

```java
boolean zBooleanValue = ((Boolean) gl8Var2.getValue()).booleanValue();  // arranging
if (zBooleanValue) {
    String strU  = tl7.U(uz4Var, R.string.ui_fileimport__move_up);
    String strU2 = tl7.U(uz4Var, R.string.ui_fileimport__move_down);
    ...
    pd8 pd8VarA = ba6.p(e0j.d(z5c.H(pd8VarK, (ix4) objS), 1.0f), ...);   // drag handle
    oe4Var = new oe4(strU, this.J, strU2, gl8VarA0, this.P);             // move handler
    pd8 pd8VarA2 = lvc.a(pd8VarA, false, (ix4) oe4Var);                  // row accessory
} else {
    // non-arranging: row onClick (preview/remove affordance)
    pd8VarK = m18.K(pd8VarK, false, null, null, (Function0) objS3, 15);
}
```

In arrange mode the row's click affordance is replaced by reorder
controls exposing `move_up`/`move_down` semantics on `this.J` (the
file list). Order feeds materialization: `rv5` creates notes in list
order; `qv5`/`sv5` append pages in list order.

## Harmony port notes

- `ImportDetailsSheet`: `@State orderedFiles` + `@State arranging`;
  header toggle only when `orderedFiles.length > 1`; arrange-mode rows
  show ↑/↓ buttons carrying the same accessibility strings; title
  input hides during arrange.
- `ImportPlan.orderedUris` carries the reordered list;
  `dispatchImportPlan` prefers it (length-checked) across all three
  destination branches.
