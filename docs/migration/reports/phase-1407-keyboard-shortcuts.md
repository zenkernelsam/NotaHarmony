# Phase 1407 修复报告：原版硬件键盘快捷键（vla/bd8 两层通路）

## 范围

原版 1.4.2 硬件键盘快捷键分两层独立于文本编辑 keymap（phase-1255）：
`MainActivity.dispatchKeyEvent → vla.a` 应用级查表（`qa8` 四维精确
匹配）+ `kom→ofk.L` 画布级 `bd8.B`/兜底链。本阶段整体移植该通路。

## 原版证据（decompiled_1.4.2）

- `qa8`：`KeyChord{keyCode,ctrl,alt,shift}` 四维等值；双参构造 mask
  位反向（(mask&2)==0→ctrl）。
- `vla.a`：Ctrl+N→xla(new_note)、Ctrl+,→zla(open_settings)、
  Ctrl+L→wla(back_to_library)、Ctrl+/→yla(open_help)；
  `vla.b`=Ctrl+Shift+N(new_window)；`cma` 帮助表末位纯 ESC。
- `if2` case1：`bma` 通道消费 ama——new_note→mqa 协程；
  settings→`lra.U(null)`；help→`lra.U(qw6)`；back→feed 末 j19 段锚定。
- `bd8.B`：Ctrl+=/+/num+→`F(1.2f)`；Ctrl+-/num-→`F(0.8333333f)`；
  Ctrl+0/num0→`ad8`→`mfc.D(1.0/current,center)`；Ctrl+Shift+E→
  `rc8`(ShowShare)；Ctrl+Shift+P→`oc8`(OpenContentManager)；
  Ctrl+R→`sc8`(ToggleRecording)；Ctrl+F→`pc8`(OpenSearch)；
  Ctrl+Home/End→`jp8` scrollToTop/Bottom。
- `f2` 兜底链（`!(Q.m instanceof rsi)` 门）：Ctrl+Z undo、
  Ctrl+Shift+Z/Ctrl+Y redo、Ctrl+C/X/V + 专用 COPY/CUT/PASTE 键、
  Ctrl+1..9 → `cxi(index)` 第 N 个可见工具（`sti.c.e+d.e` 序）、
  k0=308..311 厂商键（`G()`=k24.a() 门）→ `D()` 前工具。

## Harmony 实现

- `data/OriginalKeyboardChords.ets`（新）：`OriginalKeyChord` 接口 +
  `matchKeyChord` 四维精确匹配 + 全部键码/和弦常量（Android→
  Harmony 键码对照注释内嵌）+ `toolSelectDigitIndex`（ctrl&&!shift 门）。
- `NoteCanvasView`：根 Stack `.onKeyEvent` + 焦点接管；bd8.B 顶部分支
  逐一落 `viewport.zoomAt/setScroll`（视口中心锚）、回调上抛
  `onKeyOpenSearch/onKeyOpenContentManager/onKeyShowShare/
  onKeyToggleRecording`；兜底链 `!textEditing` 门下 undo/redo/
  选区 copy-cut-paste（`onSelectionMenuAction`）/Ctrl+1..9
  `visibleToolStates()[i]`→`selectToolById`；ESC 选区 deselect。
- `NotePage`：根 Column `.onKeyEvent` 应用级兜底——Ctrl+,→settings、
  Ctrl+L→`leaveEditor()`、Ctrl+N/Shift+N/Ctrl+/ 消费空转、
  ESC→sheet/cover dismiss 链（docScan→cover→gallery→overview→
  标题编辑）；新增 `pageOverviewSearchSignal`/`toolbarShareSignal`。
- `LibraryPage`：根 Row `.onKeyEvent`+焦点——Ctrl+N→`createAndOpen()`、
  Ctrl+,→settings、Ctrl+L→`selectFolder(null)`、ESC→`exitMultiSelect()`、
  new_window/help 消费空转。
- `PageOverviewPanel`：`searchSignal` prop → `searchActive=true`；
  搜索 TextInput 加 `defaultFocus`（Ctrl+F 后键盘输入直落）。
- `EditorToolbar`：`shareSignal` prop → `showShareSheet=true`
  （与分享钮同一 `photoImportLeaseActive` 门）。

## Fail-closed 登记

- 厂商键 308..311 → 前工具切换：S-Pen 硬件门，无通路不实现。
- Ctrl+/ 帮助路由：无 Help 面，消费空转。
- Ctrl+Shift+N 新窗口：无多窗启动器，消费空转（与原版 dropped 同语义）。
- 编辑器内 Ctrl+N：建笔记管线为库面 VM 宿主，消费空转。

## 验证

- Replay：`d02-original-keyboard-shortcuts.mjs` 67 项断言全绿。
- 构建：`note@default` 与 clean `note@ohosTest` 均通过。
- 全量 Desktop Replay 基线：1259/1259。
