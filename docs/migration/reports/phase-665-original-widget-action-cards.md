# Phase 665：原版动作小部件（CreateNote/CreateRecording WidgetProvider → form 卡片）

日期：2026-09-24
接续：Phase 664（/app/note 深链）

## 原版依据

- `CreateNoteWidgetProvider.f()` → `CREATE_NOTE` intent；
  `CreateRecordingWidgetProvider.f()` → `CREATE_NOTE` +
  `putExtra("start_recording", true)`；均 2×2 targetCell、
  home_screen。
- `hv7.i` → `Q.j` + `kx` 建笔记直开；`rd9` 消费
  `auto_start_recording_applied` 一次性标记 → 自动起录。
- 标签："Create a new note"/"Quickly create a new note."；
  "Start recording"/"Quickly create a new note with a recording."。
- 另有 3 张数据小部件（RecentNotes 4×2 列表+`show_recent`、
  NoteThumbnail+config、FolderNotes+config）—— 数据通道面。
- 详见 `docs/migration/evidence/phase-665-original-widget-action-cards.md`
  与 ADR-0632。

## Harmony 实现

- `module.json5` extensionAbilities：`NoteFormAbility`
  （`type:"form"`, `ohos.extension.form` →
  `$profile:forms_config`）。
- `forms_config.json`：`new_note_card`/`new_recording_card`
  两张 ArkTS 卡片，`defaultDimension "2*2"` +
  `supportDimensions ["2*2"]`，`updateEnabled:false`。
- `NoteFormAbility.ets`：最小 FormExtensionAbility 生命周期。
- `NewNoteCard.ets`/`NewRecordingCard.ets`：图标 + 本地化标签
  → `postCardAction(router, abilityName=NoteAbility,
  params.launch_action=create_note/create_recording_note)`。
- `LaunchActionIngress`：新增 `LAUNCH_ACTION_CREATE_RECORDING_NOTE`
  入白名单；兜底识别原版 extras `start_recording`/`start_camera`
  === true（CREATE_NOTE intent 契约）。
- `LibraryPage.drainLaunchIngress`：录音动作 →
  `createAndLaunch(autoRecord=true)` → `autoRecord:'1'` →
  NotePage `autoRecordRequested` 既有挂点。
- 新图标 `shortcut_new_recording.svg`；双语
  `form_*` 字符串。

## fail-closed 登记

- RecentNotes/NoteThumbnail/FolderNotes 三张数据小部件 +
  `show_recent` extra + `WidgetImageProvider`：需 formProvider
  数据通道与 per-form 配置 UI，登记为后续项。

## 验证

- `d05-original-widget-action-cards.mjs`：24 断言全绿。
- 连带更新 `d05-original-launcher-shortcuts.mjs`
  （createAndLaunch 签名 pin）26/26 绿。
- 全量 Desktop Replay 550/550。
- `note@default` + `note@ohosTest` 双 HAP 0 错误；卡片经
  `debug_widget` 编译通道打包进 HAP。
- 未启动模拟器/真机/Hypium。
