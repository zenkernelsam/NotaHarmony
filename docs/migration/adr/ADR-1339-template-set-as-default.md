# ADR-1339 — 捆绑模板 Set as default

- 状态：已接受
- 日期：2026-08（Phase 1403）
- 证据：`docs/migration/evidence/phase-1403-template-set-as-default.md`
- 前置：ADR-1337（图库 + 当前页应用）、ADR-1338（收藏/最近/用量）
- Replay：`docs/migration/replays/d02-original-paper-template-default.mjs`

## 决策

落地原版捆绑模板的 **Set as default**：cell 长按菜单持久化
`pdfAssetPath` 为默认模板键；新建笔记时解析并把该打包 PDF 应用到首页。

1. **持久化键**：`BundledTemplateMetaStore.defaultPaperTemplatePath` ↔
   原版 `o8b.x`。原版 `ju8` case26 在写 `o8b.x` 同时把当前 `wfc`（尺寸/
   方向/颜色）连同既有 `tr0` 回写 `o8b.w`；Harmony 纸型默认由
   `DefaultNoteTemplateRepository` 独立持有，故本切片只持久化
   pdfAssetPath（`setDefaultPath`/`clearDefaultPath`/`getDefaultPath`）。
2. **解析优先级**（原版 `wq3.b`）：`o8b.x` 可解析出 `chc` → `a1d`（打包
   模板胜出）；否则 `pfc` → `x0d`（程序化默认）。Harmony 等价：
   `getDefaultPath()` 非空且 `findBundledPaperVariantByPath` 命中 →
   应用打包 PDF；**键缺失或 catalog miss → fail-closed 回退
   `resolveDefaultTemplate` 纸型**（存储键保留，原版同语义）。
3. **消费端**（原版 `lk3`/`qp9.O` → `h1d.b(cpj,null,null,true)`）：
   `LibraryViewModel.createNote` 在 `repo.createNote` 后调用注入的
   `bundledDefaultApply` → `applyBundledTemplateDefault` 把
   `buildBundledTemplatePageBackground` 的 `PageBackground.pdf` 写到
   首页（`pages[0]`）。VM 构造处未注入时纯纸型 —— fail-closed。
4. **不记录 recents/usage**：原版 `lk3` 路径经 `f1d`→`sqc.b` 直接应用，
   不经过 `pth.t`/`qc0`；Harmony 等价——默认应用不写
   recents/usage（仅显式 UI 选择记录）。
5. **失败不回滚笔记**：原版 `lk3` 的 IOException 走 `a()` 日志支路，
   笔记照常建立；Harmony `createNote` 内 `try/catch` 后 `console.warn`。

## UI 承载

- 原版 `od7` case3：`t92` 下拉菜单内 `yl2.f("Set as default")` =
  `s86(dismiss + onSetDefaultPaperTemplate(chc))`，由 `ibn.c`/`q9l.b`
  挂在 cell 上（长按）。
- Harmony：`BundledTemplateCell.bindContextMenu(LongPress)` +
  `Menu`/`MenuItem("Set as default")` → `store.setDefaultPath`。
  原版菜单仅此一项且不含取消默认；Harmony 同。

## 版本差异登记

- 原版 `pfc` flatbuffer 把 `wfc`+`tr0` 与 `o8b.x` 耦合存储；Harmony 侧
  程序化默认与打包默认是两个独立 store —— 设置打包默认不清除纸型偏好
  （反之亦然），但消费端解析顺序与原版一致（打包路径优先）。
- 程序化纸型的 `g8b` case0 对称清除暂未接 UI（Harmony 尚无程序化
  set-default 入口）；`clearDefaultPath` 已备好。
