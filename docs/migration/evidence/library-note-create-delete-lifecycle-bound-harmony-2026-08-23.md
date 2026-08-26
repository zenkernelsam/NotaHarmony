# Harmony Evidence: Library Note Create/Delete Lifecycle Binding

Date: 2026-08-23

## Phase 514 增量（2026-08-26）

- 补审发现：晚到删除确认可打开对话框，失活后的删除/新建事务入口也可进入忙态与持久化；原设计依赖
  后续生命周期守卫丢弃结果。
- `confirmDelete()`、`deleteNoteAndRefresh()` 和 `createAndOpen()` 现在先拒绝非 `pageActive`。
  忙态防重入、上下文守卫、状态发布、失败提示和导航语义不变。
- 扩展既有笔记创建/删除生命周期 Replay 至 `TOTAL=8 FAILED=0`。

- `deleteNoteAndRefresh()` checks generation/page/viewModel after delete and in its catch path before any state write or toast.
- `createAndOpen()` checks generation/page/viewModel after creation and in catch before snapshot publication, toast, reload scheduling, or editor navigation; guard resets `createBusy`.
- Stale paths skip all memory/UI publication and navigation while durable results remain authoritative.

Replay: `d02-library-note-create-delete-lifecycle-bound.mjs` TOTAL=4 FAILED=0. No emulator, VM, device, or Hypium was started.

Full desktop replay: `REPLAY_FILES=292 PASSED=292 FAILED_FILES=0`. Static HAP packaging skipped signing and passed for both targets:

- `note@default`: `BUILD SUCCESSFUL in 12 s 702 ms`
- `note@ohosTest`: `BUILD SUCCESSFUL in 8 s 852 ms`
