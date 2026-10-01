# ADR-1343：硬件键盘快捷键（应用级 vla + 画布级 bd8）移植

- 日期：2026-10-01
- 状态：Accepted（实现面）；fail-closed 项见下
- 关联：Phase 1407；文本编辑 keymap（ADR-1199 / phase-1255）为既有
  独立通路，本 ADR 不重复覆盖

## 背景

原版 1.4.2 有两层硬件键盘分发（区别于文本字段内的编辑快捷键）：

1. **活动级**（`MainActivity.dispatchKeyEvent`）：`vla.a`/`vla.b` 以
   `qa8`（keyCode+ctrl+alt+shift 四维精确匹配）查表，KeyUp 时经
   `bma` 通道发 `lra.handleNavigationShortcut`（`if2`）——新建笔记 /
   设置 / 帮助 / 回库 / 新窗口。未命中 → 系统透传。
2. **画布级**（`kom`→`ofk.L`→`f2` case5→`bd8.B`）：缩放三连
   （±1.2/回100%，视口中心锚）、Ctrl+Home/End 滚动、Ctrl+Shift+E/P
   （ShowShare/OpenContentManager）、Ctrl+R（ToggleRecording）、
   Ctrl+F（OpenSearch）；兜底链（`!rsi` 门）含 undo/redo/选区
   copy-cut-paste/Ctrl+1..9 工具快选/厂商键前工具切换。

Harmony 此前只覆盖文本编辑 keymap（Ctrl+B/I/U 等），两层全局/
画布键无对应物。

## 决策

新增 `OriginalKeyboardChords.ets`（qa8 等价模型 + 全部和弦常量 +
`matchKeyChord` 四维精确匹配 + Harmony 键码对照），分两层接线：

- **NoteCanvasView** 根 Stack `.onKeyEvent` + `.focusable(true)` +
  `.defaultFocus(true)` = `ofk.L` 画布修饰等价。画布级和弦直接驱动
  `viewport.zoomAt/setScroll`、`undoStroke/redoStroke`、
  `onSelectionMenuAction(COPY/CUT/PASTE)`、`selectToolById`、
  `selectionTool.deselect()`；页面侧动作（搜索/页板/分享/录音）经
  `onKeyOpenSearch` 等回调上抛。`!textEditing` 兜底门 = 原版 rsi 门。
- **NotePage** 根 Column `.onKeyEvent` = 活动级兜底：Ctrl+,→
  settings、Ctrl+L→`leaveEditor()`、ESC→sheet/cover dismiss 链；
  Ctrl+N / Ctrl+Shift+N / Ctrl+/ 消费空转。
- **LibraryPage** 根 Row `.onKeyEvent` + 焦点接管：Ctrl+N→
  `createAndOpen()`、Ctrl+,→settings、Ctrl+L→`selectFolder(null)`、
  ESC→`exitMultiSelect()`、new_window/help 消费空转。
- 一律 `KeyType.Up` 触发（`lxm.a(o,1)`=ACTION_UP 等价），按下/松开
  两相均消费以拦截冒泡。

## 差异与 fail-closed 登记

| 原版 | Harmony | 理由 |
|---|---|---|
| k0 厂商键 308..311 → `D()` 前工具切换 | 不实现 | `G()`=`k24.a()` 设备门（S-Pen 遥控），Harmony 无硬件通路 |
| Ctrl+/ → qw6 help 路由 | 消费空转 | 无帮助屏幕；保留消费语义与原版一致 |
| Ctrl+Shift+N → 新窗口 | 消费空转 | 无多窗启动器；原版 dropped 时同样 return true |
| 编辑器内 Ctrl+N 建笔记 | 消费空转 | 建笔记管线属库面 VM（文件夹上下文+默认模板链），编辑器无宿主 |
| Ctrl+L 滚动锚定末 j19 段 | `selectFolder(null)` / `leaveEditor()` | 原版为 feed 内滚动锚；Harmony 取"回库根"语义等价 |
| Ctrl+V/Ctrl+Alt+V 粘贴定位 | 视口中心 `clipboardPasteTarget` | 原版 `bde` 视口适配几何；落点近似一致 |

## 验证

- `docs/migration/replays/d02-original-keyboard-shortcuts.mjs`：67 项
  断言（键码表/双分支门控/信号链路/fail-closed 登记）。
- `note@default` + clean `note@ohosTest` 构建通过；全量 Desktop
  Replay 1259/1259。
