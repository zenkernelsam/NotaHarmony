# Phase 665 证据：原版动作小部件（CreateNote/CreateRecording WidgetProvider → CREATE_NOTE）

日期：2026-09-24
关联：ADR-0632；前置 Phase 663（快捷方式 ingress）、Phase 657
（编辑器录音入口）

## 原版实现（decompiled_1.0.3）

### 五个 AppWidgetProvider（AndroidManifest.xml）

| Provider | 尺寸/配置 | 点击 intent |
|----------|-----------|-------------|
| `CreateNoteWidgetProvider` | 2×2（targetCell） | `CREATE_NOTE` |
| `CreateRecordingWidgetProvider` | 2×2 | `CREATE_NOTE` + `putExtra("start_recording", true)` |
| `RecentNotesWidgetProvider` | 4×2 | header=`CREATE_NOTE`；body=`VIEW` + `show_recent` extra；行=逐笔记打开 |
| `NoteThumbnailWidgetProvider` | 可变 + `NoteThumbnailConfigActivity` | 配置选笔记 → 缩略图 → 打开该笔记 |
| `FolderNotesWidgetProvider` | 可变 + `FolderNotesConfigActivity` | 配置选文件夹 → 笔记列表 → 打开笔记 |

`CreateNoteWidgetProvider.f()`（`CreateNoteWidgetProvider.java`）：

```java
Intent className = new Intent().setClassName(pkg, "...MainActivity");
Intent action = className.setAction("android.intent.action.CREATE_NOTE");
return action;
```

`CreateRecordingWidgetProvider.f()` 同构，追加
`putExtra("start_recording", true)`。

widget info XML（`app_widgets__create_*_widget_info.xml`）：
`targetCellWidth="2" targetCellHeight="2"`，`home_screen`，
`initialLayout` = create_note/create_recording 布局，
`previewImage` = widget_new_note/widget_new_recording。

标签字符串（`values/strings.xml`）：
- `app_widgets__widget_new_note_label` = "Create a new note" /
  `..._description` = "Quickly create a new note."
- `app_widgets__widget_recording_label` = "Start recording" /
  `..._description` = "Quickly create a new note with a recording."

### start_recording 消费端

`hv7.i`（`hv7.java:58`）：`CREATE_NOTE` → `Q.j=true` + `kx` 协程
建笔记直开（与 v50 快捷方式同一入口；`kx.invokeSuspend` opaque）。

`rd9.java:374-394`：编辑器侧 `auto_start_recording_applied`
一次性标记 —— 起录成功后写 `TRUE`，避免重复触发。即
`start_recording` 语义 = 建笔记后自动开始录音（与内建 Record
入口同一挂点语义）。

## Harmony 对齐

| 原版 | Harmony |
|------|---------|
| AppWidgetProvider receiver | `extensionAbilities` → `NoteFormAbility`（`type:"form"`, `metadata ohos.extension.form → $profile:forms_config`） |
| 2×2 动作小部件 ×2 | `forms_config.json` 两张 ArkTS 卡片 `new_note_card`/`new_recording_card`（`defaultDimension 2*2`, `supportDimensions ["2*2"]`, `updateEnabled false` —— 纯动作卡片不刷新） |
| RemoteViews 布局 + preview | `NewNoteCard.ets`/`NewRecordingCard.ets`（图标 + 本地化标签） |
| 点击 → CREATE_NOTE (+start_recording) intent | `postCardAction(router, abilityName=NoteAbility, params.launch_action=create_note/create_recording_note)` |
| hv7.i → kx 建笔记直开 | `LaunchActionIngress` 队列 → `NoteAbility` 入队 → `LibraryPage.onPageShow` drain → `createAndLaunch` |
| `start_recording` extra → `auto_start_recording_applied` → 自动起录 | `create_recording_note` → `createAndLaunch(autoRecord=true)` → `autoRecord:'1'` param → NotePage `autoRecordRequested` → `startRecording()`（既有挂点，含 pageLoadGeneration + editorDisposed 守卫） |
| 原版 intent extras 契约（start_camera/start_recording） | `LaunchActionIngress` 兜底读取 `want.parameters['start_recording']`/`['start_camera']` === true，与 `launch_action` 并列接收 |

## fail-closed 登记

1. **RecentNotesWidgetProvider**（4×2 近期笔记列表 + `show_recent`
   VIEW extra）：需 formProvider 数据通道（`updateForms` +
   `formBindingData`）把笔记快照喂给卡片渲染进程，未建 —
   登记；`show_recent` extra 同步登记。
2. **NoteThumbnailWidgetProvider + ConfigActivity**（选笔记 →
   缩略图）：需 per-form 配置 UI + 缩略像素通道 —— 登记。
3. **FolderNotesWidgetProvider + ConfigActivity**（选文件夹 →
   列表）：同上 —— 登记。
4. **`WidgetImageProvider`**（content:// 缩略图授权流）：依附于
   数据小部件，随上登记。
