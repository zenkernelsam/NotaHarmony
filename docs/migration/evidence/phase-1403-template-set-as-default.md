# Phase 1403 证据 — 捆绑模板 Set as default

## 原版 1.4.2 证据（decompiled_1.4.2）

### 入口（cell 长按菜单）

- `u7n.java:88` — cell 第三回调 `onSetDefaultPaperTemplate(chc)`（
  `yia(1, rsh, …)` 方法引用）；`q9l.b(qgc, onSelect, onFavorite,
  onSetDefault, …)` 把它作为尾随 lambda 传进 `ibn.c`。
- `od7.java` case3（~line 479）：`t92`（DropdownMenuScope）内
  `yl2.f(strW0=R.string.ui_templates__set_as_default, onClick=
  s86(function5=dismiss, bz5Var9=onSetDefault, qgcVar))` —— 即 cell 的
  长按上下文菜单中**唯一**菜单项。
- `s86.invoke`：`function5.invoke()`（关菜单）→ `bz5Var9.invoke(qgcVar.b)`
  = `onSetDefaultPaperTemplate(chc)`。

### 持久化（pth.g → ju8 case26）

- `pth.java:64` — `g(chc)`：`tee.I(M, …, ygg(16, this, chcVar))`。
- `ygg.java` case16：`h3gVar.b.e(new ju8(o8bVar, wfc, chc.e))`。
- `ju8.java` case26：
  1. 读 `o8b.w`（`pfc` flatbuffer，default-template 结构）→ 无则 `pfc.d`；
  2. `new pfc(wfc, tr0)`（保留原 `tr0` 分量，wfc=当前 size/orientation/
     color/kdj）→ `pfc.a` flatbuffers 序列化 → `ega.g(o8b.w, bytes)`；
  3. `ega.g(o8b.x, str6)` — `str6` = `chc.e` = **pdfAssetPath**。
- `g8b.java` case0（程序化模板 set-default 的对称面）：写 `o8b.w` 后
  `ega.f(o8b.x)` —— **清除打包默认路径**；`i5b` case2/3 = 清除/全量重置。

### 解析优先级（wq3.b）

- `wq3.java`：`o8b.g(b, uq3)` → 若解析出 `chc`（`o8b.x` 路径 + 目录反查）
  → 返回 `a1d(chc)`（打包默认胜出）；否则 `o8b.h(r5)` → `pfc` →
  `x0d(pfc)`（程序化默认）。

### 消费端（qp9.O = lk3 → h1d.b）

- `qp9.java:40` — 建笔记流持有 `lk3(h1dVar, …)`。
- `lk3.java`（~line 183/234）：`h1d.b(cpjVar, null, null, true, ck3)` —
  `b1d=null` → 内部经 `wq3.b` 解析默认选择 → `f1d` → `sqc.b(bpj, path)`
  应用到首页；随后 `xbb.d` 校验结果；失败走 `a(IOException("The default
  template could not be read"))` 日志支路 —— **不回滚已建笔记**。
- 此路径不经 `pth.t`/`qc0` —— **默认应用不写 recents/usage**（仅显式
  UI 选择 `vuh.q`→`a1d` 时记录）。

## Harmony 落点

| 原版 | Harmony |
|------|---------|
| `o8b.x`（pdfAssetPath） | `BundledTemplateMetaStore.defaultPaperTemplatePath` |
| `od7` case3 t92 菜单 | `BundledTemplateCell.bindContextMenu(LongPress)` + `MenuItem` |
| `pth.g(chc)` | `PaperTemplateGallery.setDefault(variant)` → `setDefaultPath` |
| `wq3.b` 解析+回退 | `applyBundledTemplateDefault`：path 空 → return；catalog miss → warn+return |
| `lk3`/`h1d.b` | `LibraryViewModel.createNote` 注入 `bundledDefaultApply` |
| `sqc.b` 应用到首页 | `buildBundledTemplatePageBackground` + `pageRepo.updatePage(pages[0])` |
| 不写 recents | `applyBundledTemplateDefault` 不调 `recordUsed` |
| 失败不回滚 | `createNote` 内 try/catch `console.warn` |

## 复核

- `note@default` 与 `note@ohosTest` 构建见 Phase 1403 报告。
- Replay：`d02-original-paper-template-default.mjs` 26 项断言。
