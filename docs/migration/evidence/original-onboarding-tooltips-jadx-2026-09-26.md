# 原版引导气泡链（pq9 / onboardingTooltipSeen）JADX 证据

- 日期：2026-09-26
- 来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\`（只读原版资料）
- 关联：ADR-0660 / Phase 712

## 1. 枚举

`sources/defpackage/pq9.java`（静态块，序号→枚举名逐位）：

| ordinal | 枚举名 | JADX 字段 |
|---|---|---|
| 0 | NEW_NOTE | `pq9.I` |
| 1 | FIRST_TRAY_OPENED | `pq9.J` |
| 2 | FIRST_INK_INSERT | `pq9.K` |
| 3 | FIRST_IMAGE | （字段声明被 JADX 丢弃） |
| 4 | FIRST_RECORDING | `pq9.L` |
| 5 | FIRST_TRANSCRIPT | `pq9.M` |
| 6 | FIRST_TEXT | （字段声明被丢弃） |
| 7 | FIRST_IMPORT | `pq9.N` |
| 8 | FIRST_UNDO_REDO | `pq9.O` |
| 9 | FIRST_HIGHLIGHTER | （字段声明被丢弃） |
| 10 | FIRST_NOTE_COMPLETED | `pq9.P` |
| 11 | COMPACT_ORGANIZE | `pq9.Q` |

## 2. 持久化

`sources/defpackage/hq9.java`：

```java
public static final eua j = new eua("onboardingTooltipSeen");
public static final eua k = new eua("defaultNotesRolePromptSeen");
public static final eua l = new eua("sixMonthsPlusOnboardingSeenUserIds");
```

`hq9.c`：读 `Set<String>` → `pq9.valueOf(str)` 容错映射（未知串
记日志跳过）→ `gq9(seenSet, defaultNotesRolePromptSeen, userIds)`。

`js7` coroutine：tooltip "Got it" 交互 → 对应 `pq9` 写入 seen 集。

## 3. 渲染与定位

- `zy7.java`：按 kind 取 `data_onboarding__*_tooltip_text` 本地化
  文案 + `data_onboarding__got_it` 按钮，`tpe.b(...)` 动画可见性。
- `k9f.java`：方位码 1=上、2=下（回退上）、3=左、4=右、5/6=RTL
  变体；优选方位放不下时回退并钳制在界内。
- `l9f.java`/`b4j.java`：气泡与锚点组合。
- `fsi.h(kind, pos, cond, anchor, content)`：锚定包装器；
  `fsi.g` 内部校验 `!seen`。

## 4. 站点（逐位）

| 文件:行 | 代码 | 含义 |
|---|---|---|
| `x90.java:10523` | `fsi.h(pq9.N, 3, z7, ...)` | 页管理器开关，`z7`=任一页 `nz9.l()` 非空（有内容） |
| `x90.java:10528` | `fsi.h(pq9.O, 3, gl8Var5, ...)` | undo/redo 手势提示，`gl8Var5`=undo 可用 |
| `ajh.java:406` | `fsi.h(pq9.P, bool==null?4:i5, ...)` | 首条笔记完成（库侧），默认 pos4 右 |
| `cqi.java:207` | `fsi.h(pq9.M, 3, true, ...)` | 转写气泡（feature_learn 面） |
| `enh.java:28` | `fsi.h(pq9.Q, 2, z2, ...)` | 紧凑整理（库侧），pos2 下 |
| `ipi.java:1533` | `pq9.J` | 样式托盘气泡 |
| `gaj.java:875` | `pq9.L` | 录音回放气泡宿主 |
| `rh8.java:1936` | `!set3.contains(pq9.L) && set3.contains(pq9.I)` | L 前置 = I 已见 |
| `rh8.java:2035+` | `pq9Var = r5fVar instanceof k5f ? pq9.K : null` | 笔记态机：e5f→I、k5f→K、z4f→无 |
| `cq.java:1962` | `cq.p(r5fVar, ..., pq9Var2, ...)` | 笔记态气泡通用宿主 |
| `ys2.java:1493` | `!set3.contains(pq9.J) && set3.contains(pq9.I)` | J 前置 = I 已见 |
| `cu8.java:10` | `cq.w0(dx(mq9.b,16),...,setOf(pq9.S))` | 通用宿主按 kind 过滤挂起流 |
| `ya0.java:980` | `fsi.g(pq9Var, ...)` | 通用宿主动态 kind |

## 5. 文案（`resources/res/values/strings.xml`）

```
data_onboarding__new_note_tooltip_text
data_onboarding__first_tray_opened_tooltip_text
data_onboarding__first_ink_insert_tooltip_text
data_onboarding__first_image_tooltip_text
data_onboarding__first_recording_tooltip_text
data_onboarding__first_transcript_tooltip_text   ← Learn 边界，未移植
data_onboarding__first_text_tooltip_text
data_onboarding__first_import_tooltip_text
data_onboarding__first_undo_redo_tooltip_text
data_onboarding__first_highlighter_tooltip_text
data_onboarding__first_note_completed_tooltip_text
data_onboarding__compact_organize_tooltip_text
data_onboarding__got_it
```

## 6. Harmony 移植映射

| pq9 | Harmony 锚点 | 触发 | Placement |
|---|---|---|---|
| I | EditorToolbar 样式选项按钮 | aboutToAppear `!seen` | Bottom |
| J | 同上（同一 bindPopup 换文案） | `showColorPicker` 打开 && `seen(I)` | Bottom |
| K | NoteCanvasView 元素浮层（墨迹 bounds） | 载入/提交后 `completedStrokes>0` | 上→下回退 |
| 3 | NoteCanvasView 元素浮层（图像 bounds） | 载入/提交后 `imageBlocks>0` | 左→右回退 |
| L | NotePage Recordings 按钮 | `recordings>0 && seen(I) && !seen` | Left |
| 6 | EditorToolbar `toolId==='text'` 按钮 | 工具首次选中 | Bottom |
| N | EditorToolbar ▦ 页面板开关 | `noteHasContent`（= `!emptyNoteActions`） | Left |
| O | EditorToolbar ↶ 撤销按钮 | `canUndo` 转 true | Left |
| 9 | EditorToolbar `toolType===HIGHLIGHTER` 按钮 | 工具首次选中 | Bottom |
| P | LibraryPage 首卡/首行 | `notes.length>0 && !seen` | Right |
| Q | LibraryPage Folders 入口（侧栏 New Folder / compact ☰） | `notes.length>0 && !seen` | Bottom |

`mask:false` + `autoCancel:false`：非模态（锚点控件仍可点按）且
仅 "Got it" 关闭——对齐 js7 唯一关闭路径。
