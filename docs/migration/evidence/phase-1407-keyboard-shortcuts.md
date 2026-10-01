# Phase 1407 — 原版硬件键盘快捷键（应用级 + 画布级）

> 证据基线：`decompiled_1.4.2`（MainActivity.java / vla / qa8 / if2 / lra /
> bd8 / f2 / pa8 / zp6 / kom / cma / npb）。与 phase-1255 的文本编辑
> keymap（hke/k09/syh → xl6 48 命令）是两套独立通路，互不覆盖。

## 1. 原版通路拓扑

```
KeyEvent
  ├─ Compose 焦点链（画布 onKeyEvent：kom → ofk.L → bd8.onKeyEvent
  │   = f2 case5：bd8.B() 顶部分支 + rsi 门兜底链）
  │     └─ 文本字段编辑中：TextField 先消费（syh 表），未消费上冒
  └─ Activity.dispatchKeyEvent（Compose 未消费兜底）
        ├─ vla.a(keyEvent)：new-window 和弦特例（无启动器也消费）
        ├─ vla.b(keyEvent)：qa8 查表 → ama → ACTION_UP 时
        │     bma.a.f(ama) → lra.handleNavigationShortcut（if2）
        └─ null → super.dispatchKeyEvent 系统透传
```

`qdn.a(keyEvent) || !l().d()` 是 IME/组合键前置门——先过 Compose，再
到活动级查表。两级先后关系 = Harmony 的「画布子组件先消费、未消费
冒泡至页面根」。

## 2. 键码与修饰键模型

`qa8 = KeyChord{keyCode:int, ctrl:boolean, alt:boolean, shift:boolean}`，
`equals` 四维全等。双参构造 `qa8(i, mask)` 的位语义为反向：

```java
this(i, (mask & 2) == 0, (mask & 4) == 0, (mask & 8) == 0)
//       ctrl            alt             shift
```

即 mask=12(0b1100)={ctrl:T,alt:F,shift:F}；mask=4={ctrl:T,alt:F,shift:T}；
mask=14=纯 ESC 无修饰。查表是精确匹配——Ctrl+N+Shift ≠ Ctrl+N。

`pa8` 键码表（`ofk.e(AndroidKeyCode)`）：j=7(0),k..s=8..16(1-9),
t=81(+),u=69(-),v=70(=),z=33(E),A=34(F),E=44(P),F=46(R),H=50(V),
I=52(X),J=53(Y),K=54(Z),x=31(C),Q=111(ESC),R=122(HOME),S=123(END),
c0=144(num0),d0=156(num-),e0=157(num+),U/V/W=277/278/279(CUT/COPY/
PASTE)，k0=308..311（厂商遥控键）。

Harmony 对照（@ohos.multimodalInput.keyCode）：0-9=2000..2009，
A-Z=2017..2042，COMMA=2043，MINUS=2057，EQUALS=2058，SLASH=2064，
PLUS=2066，ESC=2070，MOVE_HOME=2081，MOVE_END=2082，
NUMPAD_0..9=2103..2112，NUMPAD_SUBTRACT=2115，NUMPAD_ADD=2116，
COPY=2620/PASTE=2622/CUT=2624（原序 CUT/COPY/PASTE=277/278/279）。

## 3. 应用级和弦（vla.a + vla.b + cma 帮助表 ESC）

| 和弦 | 原版标记 | 动作（if2/lra） | Harmony 落点 |
|---|---|---|---|
| Ctrl+N | xla `new_note` | mqa 协程建并打开笔记（feed 含 j19 门） | LibraryPage：`createAndOpen()`；编辑器内 fail-closed 消费（跨面 VM 无宿主） |
| Ctrl+Shift+N | vla.b `new_window` | `oim.a(config)` 多窗启动器；无则记日志消费 | 消费空转（Harmony 侧无多窗通路）——与原版 dropped 语义一致 |
| Ctrl+, | zla `open_settings` | `lra.U(null)` → settings 路由 | `navigateToSettings()`（库/编辑器同） |
| Ctrl+/ | yla `open_help` | `lra.U(qw6.INSTANCE)` → help 路由 | fail-closed 消费空转（无帮助面） |
| Ctrl+L | wla `back_to_library` | feed 末 j19 后笔记段锚定（zo8/b0 效果） | 库：`selectFolder(null)`；编辑器：`leaveEditor()` |
| ESC | `qa8(111,14)` `dismiss_deselect` | 取消选中/解散面 | 库：`exitMultiSelect()`；画布：选区 deselect；页面：sheet/cover dismiss 链 |

`vla.b` 未命中 → `super.dispatchKeyEvent`（系统透传）；Harmony 对应
`return false` 冒泡。

## 4. 画布级和弦（bd8.B + f2 兜底链）

KeyUp 分发：`lxm.a(db8.o(event), 1)` = ACTION_UP 才触发动作；命中和弦
按下/松开两相都消费（返回 TRUE）。

顶部分支（`bd8.B`，无 rsi 门——文本编辑中同样生效）：

| 和弦 | 原版 | Harmony |
|---|---|---|
| Ctrl+= / Ctrl++ / Ctrl+num+ | `F(1.2f)` → `mfc.D(1.2, center)` | `viewport.zoomAt(cx,cy,1.2)` |
| Ctrl+- / Ctrl+num- | `F(0.8333333f)` | `zoomAt(cx,cy,0.8333333)` |
| Ctrl+0 / Ctrl+num0 | `ad8` → `mfc.D(1.0/current, center)` | `zoomAt(cx,cy,1/zoom)` |
| Ctrl+Shift+E | `ea1.p(rc8 ShowShare)` | `onKeyShowShare` → `toolbarShareSignal` → `showShareSheet=true` |
| Ctrl+Shift+P | `ea1.p(oc8 OpenContentManager)` | `onKeyOpenContentManager` → `showPageOverview=true` |
| Ctrl+R | `ea1.p(sc8 ToggleRecording)`，`T.g.F` 可用性门 | `onKeyToggleRecording` → session 存在门 + `isOriginalRecordingCaptureActive` 分支 |
| Ctrl+F | `V.a.f(egj)` + `pc8 OpenSearch` | `onKeyOpenSearch` → 页管理面板 + `searchSignal` → `searchActive=true` + 搜索框 defaultFocus |
| Ctrl+Home | `jp8(mfc,2)` scrollToTop | `setScroll(scrollX, 0)` |
| Ctrl+End | `jp8(mfc,1)` scrollToBottom | `setScroll(scrollX, canvasH - paperH*zoom)` |

兜底链（`!(Q.m instanceof rsi) || P.w==null` 门 → Harmony `!textEditing`）：

| 和弦 | 原版 | Harmony |
|---|---|---|
| Ctrl+Z | `E()` undo（canUndo 门内） | `undoStroke()` |
| Ctrl+Shift+Z / Ctrl+Y | `C()` redo | `redoStroke()` |
| Ctrl+C / COPY 键 | `w60` 协程 → msf 选区剪贴板 | `onSelectionMenuAction(COPY)`（isActive 门） |
| Ctrl+X / CUT 键 | cut | `onSelectionMenuAction(CUT)` |
| Ctrl+V / Ctrl+Alt+V(qc8) / PASTE 键 | `bde` 视口定位粘贴 | 视口中心 `clipboardPasteTarget` + `PASTE`（`clipboardAvailable` 门） |
| Ctrl+1..9（非 numpad） | `cxi(index)` → `N3(sti.c.e, sti.d.e)` 第 N 个可见工具 | `visibleToolStates()[idx]` → `selectToolById` |
| 厂商键 308..311 | `k0` + `G()`=k24.a() 硬件门 → `D()` 前工具切换 | **fail-closed**（无硬件通路） |

ESC 在画布层：活跃选区 → `selectionTool.deselect()`（`selectionVisible=false`
+ 控制回调复位，与既有 deselect 路径同）；无选区 → 冒泡页面层 dismiss。

## 5. 焦点与分层

- 画布根 Stack：`.focusable(true).defaultFocus(true)` —— ofk.L 画布
  修饰等价；文本编辑中 TextArea 持焦、未消费键上冒画布（与原版
  Compose 链一致）。
- NotePage 根 Column：`.focusable(true)` —— 画布未渲染（空笔记）时
  页面根仍可收应用级和弦。
- LibraryPage 根 Row：`.focusable(true).defaultFocus(true)`。

## 6. Fail-closed 登记

- `k0` = 厂商键 308..311（S-Pen 遥控等）→ `D()` 前工具切换：
  `G()` = `k24.a()` 设备能力门 + `h45.b(h35.q0)` flag——Harmony 无
  对应硬件通路，**不实现**。
- `qw6` 帮助路由：Ctrl+/ 和弦保留消费语义但无目标面（无 Help
  屏幕），记为 fail-closed。
- 编辑器内 Ctrl+N：原版活动级建笔记可跨面触发；Harmony 建笔记管线
  属于库面 VM（文件夹上下文 + 默认模板/planner 消费链），编辑器内
  无宿主 → 消费空转登记。
- Ctrl+Shift+N 新窗口：消费空转（原版无启动器时同语义）。
