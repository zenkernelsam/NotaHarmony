# ADR-0665: Original folder-delete cascade (kcj count matrix) — supersedes ADR-0158

- **Status**: Accepted
- **Phase**: 717
- **Supersedes**: ADR-0158 (folder-subtree delete preserves notes)
- **Evidence**: `docs/migration/evidence/original-folder-delete-cascade-jadx-2026-09-25.md`

## Context

ADR-0158 decided that deleting a folder preserves its notes by unfiling
them (`folder_id = NULL`, notes stay in the library). That decision was
made before the original delete dialog and its data plumbing were
decompiled. The original contract is now fully evidenced and contradicts
it:

1. `kcj.java` (`kcj.a(title, i, i2, confirm, cancel, ...)`) renders a
   nine-case message matrix keyed on `i` = descendant folder count and
   `i2` = subtree note count. Every non-empty variant says
   `Deleting "%1$s" will also delete …` — the original UI explicitly
   promises cascade deletion of child folders **and** notes.
2. `gsi.java:936` feeds the matrix from `fq4.k()` (descendant folder
   count) and `fq4.h().size()` (subtree note-id set size); `vad.java:143`
   shows `k()` accumulates `size + Σ children.k()` (recursive descendant
   folders) and `h()` dedups the folder's own notes plus every
   descendant's note set.
3. Harmony's dialog instead claimed "Its notes will move to All Notes."
   — a wrong promise vs the original, and the old behavior silently
   unfurled notes the original user was told would be deleted.

## Decision

Port the original cascade semantics as **soft-delete** (the original
routes deleted notes through its trash surface as well — deletion ≠
permanent destruction):

1. `FolderRepositoryImpl.deleteFolder` (same transaction as before):
   every note in the deleted subtree gets `folder_id = NULL` **and**
   `deleted_at = Date.now()` before the folder rows are removed. Notes
   land in Recently Deleted and stay restorable; `folder_id` is still
   nulled explicitly so no trash row dangles a dead reference beyond the
   `ON DELETE SET NULL` fallback.
2. `LibraryViewModel.publishCommittedFolderDelete` drops the trashed
   note ids from the projection (`continue` in the `moved` set) and the
   root-level `committedNotes` path filters `deletedAt !== null`, so no
   stale cards survive.
3. `LibraryPage.confirmDeleteFolder` computes the subtree with
   `isFolderInSubtree` (includes the root), derives
   `childFolders = subtreeIds.length - 1` (descendants only, matching
   `fq4.k()`), counts active notes (`getAllNotes` already excludes
   trashed) whose `folderId` is inside the subtree, and renders the
   nine-case matrix via `folderDeleteDetail` → new
   `folder_delete_detail_*` resources with verbatim English text.
4. Dialog chrome: title `Delete folder?` (`ui_folder__delete_folder_message`),
   buttons Cancel + destructive Delete (original labels are the design
   system's generic Confirm/Cancel; Harmony keeps its established
   destructive `Delete` label — documented deviation, affordance is
   clearer for a destructive op). `i==0 && i2==0` maps to a bare
   `"%s"` detail line (the original renders no detail row at all;
   ArkUI AlertDialog requires a message so the folder name is shown).

## Consequences

- Deleting a folder now matches the original promise: child folders are
  removed (existing `ON DELETE CASCADE` on `parent_id`) and subtree notes
  move to Recently Deleted instead of silently surviving in All Notes.
- Notes are recoverable from Recently Deleted — no permanent-loss
  regression vs ADR-0158's safety motivation.
- `FolderDeleteResult.movedNoteIds` keeps its name for API stability but
  now identifies trashed (not relocated) notes — annotated in source.
- The old replay `d02-folder-subtree-delete-preserves-notes` is retained
  but updated: the transactional ordering it pins (subtree note update
  before folder delete) is unchanged; its assertions now describe
  soft-delete.
- Replay: `d02-original-folder-delete-cascade.mjs` (43 pins).

## Limitations

- No runtime verification (no emulator/device session); behavior is
  pinned by source replay + static build.
- Original zh wording is not extractable from the English APK resources;
  zh strings are faithful translations, not verbatim originals.
