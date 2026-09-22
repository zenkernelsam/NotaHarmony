# 原版证据：选区菜单动作完成后清空选区（dhb → fvbVar.a()）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 600 依据。

## 1. `dhb` dsc 分发的 `fvbVar.a()` 终态

`fvb.a()` = `m.clear(); n = null; a.d(null)`——选区状态置空。

| dsc ordinal | 动作 | 成功后清选区 |
|---|---|---|
| 0 STYLE | nsc 样式弹层 | 保留（弹层依附选区） |
| 1 COPY | `lg2Var.c.a = cg2Var`（写剪贴板） | **清**（`fvbVar2.a()`） |
| 2 CUT | `vsc` → `lg2.d` | **清**（`r2.a()`） |
| 3 DUPLICATE | `vsc` → `lg2.b` → `fvbVar.a()` → `e()` | **清旧选区**，`e()` 重选粘贴副本 |
| 4 GROUP | `kk9` 协程（`size>=2`） | **清** |
| 5 UNGROUP | `wsc` 协程（非空） | **清** |
| 6-9 SEND_* | `xscVar.q(ktc, lambda)` | **清**（`q()` 内 `this.K.a()` 无条件——Phase 601 修正） |
| 10 DELETE | `kk9` 协程 | **清** |
| 11/12 CONVERT_* | 识别转换流 | 选区被转换取代 |
| 13 EDIT_MATH | `x08` 事件 → 数学编辑器 | 保留 |
| 14 CROP | `fvbVar.e(true)` | 保留（`itc.c`=crop 态） |
| 16/17 FLIP_H/V | `mub` 协程 | **清** |
| 18/19 LOCK/UNLOCK | `u5j` 切换 `element.t` | **清** |
| 20 DESELECT | `ftc.h=true` deselectMode | 保留（模式内） |
| 21 MORE | `msc.b` 折叠 | 保留 |

## 2. `lg2` 剪贴板协程

- `lg2.b`（DUPLICATE）：`fvbVar.a()` 清旧选区 → `e(cg2,…)` 粘贴，
  粘贴路径尾部 `ne9Var.d(tab.i(...)/itc/gtc)` **重选新粘贴副本**。
- `lg2.d`（CUT）：剪贴板写入 + `fvb.a()`。
- `dhb` case1（COPY）：`gg2VarG.b()` 载荷 → `lg2Var.c.a = cg2Var`
  提交成功 → `fvbVar2.a()`。

## 3. Harmony 侧

原实现：COPY/GROUP/UNGROUP/FLIP/LOCK 后保留选区，GROUP/UNGROUP
甚至 `selectElementIds` 重选成员——与原版终态相反。
本 Phase 五处全部改为成功后 `clearSelectionWithRegisterReset()`
（`fvbVar.a()` 等价）；DUPLICATE 经 `pasteClipboard` 内部
`selectElementIds` 已天然重选副本，等价。
