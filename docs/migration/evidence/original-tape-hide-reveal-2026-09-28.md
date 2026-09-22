# 证据：原版全局 Hide/Reveal Tapes（2026-09-28，Phase 583）

证据源：`decompiled_1.0.3/sources/defpackage/*.java`（1.0.3 反编译）。

## 1. 入口行：胶带工具设置项 `o94.java`

`o94.java:271-286` case 14 为胶带工具设置行，按布尔状态二选一：

- 未揭示 → 图标 `ui_tools__tape_conceal` + 文案 `ui_tools__reveal_tapes_action`（"Reveal Tapes"）；
- 已揭示 → 图标 `ui_tools__tape_reveal` + 文案 `ui_tools__hide_tapes_action`（"Hide Tapes"）。

## 2. UI 状态：`jg9.n = tapesRevealed`

`jg9.java` 的 `toString()` 直接打印 `tapesRevealed=...`。`mpi.b`（画布
composable 构造）的第三个 combine 输入来自 `ufb`：将当前可见胶带 id 集
(`g0`) 与 `fvb.l`（已揭示集合）经 `uf0` 合并 —— `uf0` case 4 的语义为
**任意**可见胶带已揭示即置真。

## 3. 动作：`oh9 = OnToggleTapesRevealed` → `np0` case5

`ti9.java:360-380` 处理 `oh9`：

1. 读取当前可见胶带 id 集合；空集直接 return（`ti9:362`）。
2. 判定是否**全部**可见胶带已在已揭示集合中。
3. 派发 `np0(z, set, 5)`。

`np0.java` case 5 依据该布尔对已揭示 id 寄存器执行：

- 全部已揭示 → `ys2.H`（差集）→ 整组隐藏；
- 否则 → `ys2.J`（并集）→ 整组揭示。

`ys2.J`/`ys2.H` 在 `ys2.java` 中分别为 union/subtraction 帮助函数。

## 4. 会话级状态：`yd9.j = revealedTape`

`yd9.java` 为 `NoteSessionState`，字段 `j` 即 `revealedTape`。`ne9.java`
经 `c(ix4)` 做不可变替换更新。**不持久化** —— 会话结束即丢弃。

渲染参数链：`pj2` 将 `yd9Var2.j` 传入 `gvb`（`gvb.k = revealedTape`，
`toString()` 直接打印 `revealedTape=`），再进入 `AccumulatedState` 与
tile/render 参数。

## 5. 渲染门：`i16` 的 `ifeVar` 条件

`i16.java:151-175`：胶带元素构建渲染数据时，`ifeVar`（胶带图案层，缺省
`ife.STRIPES`）在 reveal 条件为假时置 `null` —— 图案层被抑制；笔迹本体
仍经 `mwd.o` 烘焙路径绘制。`i16:208-228` 为已揭示胶带准备额外路径层
（wet-reveal 揭示层，`l0f.A` + `e1f` 按 `revealedTapeIds` 过滤）。

## 6. 点按揭示：`xtc.b`

`xtc.java` 的 `b(long)` 命中检测点下所有胶带元素，收集 id 后派发 `ej9`
（case 20）加入已揭示集合。

## 7. Harmony 对齐（Phase 583）

| 原版 | Harmony |
| --- | --- |
| `yd9.j`/`gvb.k` 会话级 revealedTape 集合 | `NoteCanvasView.revealedTapeIds: Set<string>`（不持久化） |
| `i16` `ifeVar=null` 抑制图案层 | `StrokeCanvasPainter.revealedTapeIds` 门控 `renderTapePattern`；笔迹本体照常绘制 |
| `oh9`→`ti9`→`np0` case5 全量并/差集 | `NoteCanvasView.toggleTapesReveal()`：全揭示→delete，否则→add |
| `ti9:362` 空集 no-op | `toggleTapesReveal` 首行 `tapeIds.length === 0` return |
| `uf0` case4 ANY → `jg9.n` | `emitTapeRevealState()` 发出 `(tapeCount, anyRevealed)` |
| `o94` case14 行标签翻转 | `NotePage.buildEditorOptionsMenu()`：`anyTapeRevealed ? hide_tapes : reveal_tapes` |

已知偏差（fail-closed 记录）：原版 wet-reveal 层（`l0f.A`/`p0f`）为揭示
动画/高亮承载层，最终派发函数未反编译成功 —— Harmony 仅以 `ife=null`
等价的"去图案化"呈现揭示态；点按揭示（`xtc`）本期未移植（原版入口在
胶带工具命中路径内，Harmony 尚无胶带工具入口）。

Replay：`docs/migration/replays/d02-original-tape-hide-reveal.mjs`
（19 项断言）。
