# Evidence: Folder selection lifecycle bound

Date: 2026-08-24 (Asia/Shanghai)

## Source review

- File: note/src/main/ets/ui/library/LibraryPage.ets
- Function: selectFolder
- Before: success and failure continuations used isCurrentNotesRequest or a weaker inline tuple; the helper inferred
  the current lifecycle, so a rebuilt page could make a captured old request appear current.
## Change

- Captured lifecycleGeneration before starting folder selection.
- Passed it to all three continuation guards: post-query publication, post-thumbnail drawer close, and failure toast.
- Replaced the weaker inline catch tuple with the shared complete identity check.

## Phase 525 增量（2026-08-29）

- 继续补审发现：Phase 354 只保护 `selectFolder()` 的异步续体，入口未先检查 `pageActive`；失活页面的晚到
  菜单/抽屉点击仍会改写 `currentFolderId`、递增请求代数并启动查询。
- `selectFolder()` 第一行现在拒绝 `!pageActive || this.viewModel === null || this.folderBusy`，之后才捕获
  查询上下文并发布当前文件夹。原生命周期/request tuple、缩略图和抽屉关闭 guard 不变。
- 专项 Replay 扩展至 `TOTAL=11 FAILED=0`，锁定入口顺序以及失活/活动选择模型。

## Verification

- Focused replay: docs/migration/replays/d02-library-folder-selection-lifecycle-bound.mjs (7/7).
- Full Desktop Replay: `REPLAY_FILES=321 PASSED=321 FAILED_FILES=0`.
- Existing `d02-library-query-generation.mjs` now requires the captured lifecycle identity across all three folder-selection guards (8/8).
- Dual HAP static build: ohosTest BUILD SUCCESSFUL in 9 s 174 ms; main BUILD SUCCESSFUL in 50 s 871 ms.
- No simulator, virtual machine, physical device, or Hypium execution.
