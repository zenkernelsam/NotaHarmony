# Phase 1403 — 捆绑模板 Set as default（o8b.x / wq3.b / lk3 等价）

- ADR：`docs/migration/adr/ADR-1339-template-set-as-default.md`
- 证据：`docs/migration/evidence/phase-1403-template-set-as-default.md`
- Replay：`docs/migration/replays/d02-original-paper-template-default.mjs`（26 项）

## 背景

Phase 1401/1402 补齐了图库、当前页应用、收藏/最近/用量。原版 cell 长按
菜单还有第三项能力 —— **Set as default**（`ui_templates__set_as_default`），
把打包 variant 持久化为新建笔记的默认模板。本 Phase 落地该切片。

## 原版证据

- **入口**：`u7n.e` 的 `onSetDefaultPaperTemplate(chc)`；`od7` case3 在
  cell 的 `t92` 下拉（长按上下文菜单）中渲染唯一菜单项
  "Set as default"（`s86` = dismiss + 回调）。
- **持久化**：`pth.g(chc)` → `ygg(16)` → `ju8` case26 ——
  `ega.g(o8b.w, pfc(wfc,tr0))` + `ega.g(o8b.x, chc.e)`；
  程序化 set-default（`g8b` case0）对称清除 `o8b.x`。
- **解析**：`wq3.b` — `o8b.x` 命中 `chc` → `a1d`（打包胜出）；
  否则 `pfc` → `x0d`。
- **消费**：`lk3`（`qp9.O` 建笔记流）→ `h1d.b(cpj,null,null,true)` →
  `f1d`/`sqc.b` 应用到首页；**不经 `pth.t`**（默认应用不写
  recents/usage）；IOException 只进 `a()` 日志支路。

## Harmony 实现

- `BundledTemplateMetaStore`：新增 `defaultPaperTemplatePath` 键 +
  `getDefaultPath`/`setDefaultPath`/`clearDefaultPath`（mutex + flush，
  失败带 tag 抛出）。
- `BundledTemplateCell`：`bindContextMenu(LongPress)` + `MenuItem`
  "Set as default" → `onSetDefault`；gallery `setDefault(variant)` 写
  `rawfilePath`，失败 `console.warn`（原版 coroutine 同样无 UI 反馈）。
- `BundledPaperTemplateApply.applyBundledTemplateDefault(context, db,
  noteId)`：默认路径空 → 早退；`findBundledPaperVariantByPath` miss →
  warn+return（fail-closed 保留纸型默认，存储键保留）；命中 → 复用
  `buildBundledTemplatePageBackground` 构建 `PageBackground.pdf` 写首页。
- `LibraryViewModel(repo, bundledDefaultApply?)`：`createNote` 在
  `repo.createNote` 之后调用注入函数；异常 catch + warn 不回滚笔记；
  未注入 → 纯纸型（fail-closed）。`LibraryPage` 构造处接线 context+db。

## 范围外（登记）

- 程序化纸型 set-default 的 `g8b` 对称清除 —— Harmony 尚无程序化
  set-default UI，`clearDefaultPath` 已备好。
- `tr0`/`wfc` 与打包路径的 flatbuffer 耦合 —— Harmony 双 store 独立，
  消费端解析顺序与原版一致。
- 页面范围应用（`olm`/`h07` all_pages/select_pages）、repeat_template、
  My Templates、covers/planners —— 程序化模板设置面专属，另行登记。

## 验证

- Replay `d02-original-paper-template-default`：26 项断言全绿。
- 全量基线、`note@default`/`note@ohosTest` 构建：见文末提交记录。
