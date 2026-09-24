# ADR-0632：原版动作小部件（CreateNote/CreateRecording → Harmony form 卡片）

- 状态：已接受
- 日期：2026-09-24
- 关联：Phase 665；前置 ADR-0630（快捷方式）、ADR-0631（深链）；
  证据 `evidence/phase-665-original-widget-action-cards.md`；
  Replay `d05-original-widget-action-cards.mjs`

## 背景

原版注册 5 个 AppWidgetProvider，其中 2 个为 2×2 纯动作小部件：
`CreateNoteWidgetProvider` 点击发 `CREATE_NOTE` intent，
`CreateRecordingWidgetProvider` 发 `CREATE_NOTE` +
`start_recording=true` extra；`hv7.i` → `kx` 协程建笔记直开，
录音语义由编辑器侧 `auto_start_recording_applied`（rd9）一次性
标记落地。其余 3 个为数据小部件（近期列表/缩略+配置/文件夹+
配置）。Harmony 对应物为 FormExtensionAbility + ArkTS 卡片。

## 决策

1. `module.json5` 新增 `extensionAbilities` 条目
   `NoteFormAbility`（`type:"form"`, `ohos.extension.form` →
   `$profile:forms_config`）。
2. `forms_config.json` 声明两张 2*2 ArkTS 卡片
   （`new_note_card`/`new_recording_card`，`uiSyntax:"arkts"`,
   `updateEnabled:false` —— 纯动作不刷新）。
3. `NoteFormAbility.ets` 实现最小生命周期（onAddForm 返回空
   FormBindingData；update/remove 空实现）。
4. `NewNoteCard.ets`/`NewRecordingCard.ets`：图标 + 本地化标签，
   点击 `postCardAction(router, abilityName=NoteAbility,
   params.launch_action)`。
5. `LaunchActionIngress` 新增 `create_recording_note` 动作；并
   兜底读取原版 intent extras（`start_recording`/`start_camera`
   === true）—— 兼容 CREATE_NOTE intent 契约的其它投递方。
6. `LibraryPage.drainLaunchIngress`：`create_recording_note` →
   `createAndLaunch(autoRecord=true)` → `autoRecord:'1'` param →
   NotePage `autoRecordRequested` 既有挂点（pageLoadGeneration +
   editorDisposed 守卫）—— 对应 `auto_start_recording_applied`
   一次性语义。

## 差异登记（fail-closed）

- RecentNotesWidgetProvider（列表 + `show_recent` extra）、
  NoteThumbnailWidgetProvider + config、FolderNotesWidgetProvider
  + config、WidgetImageProvider：需 formProvider 数据通道与
  per-form 配置 UI，本 Phase 未建 —— 全部登记为后续项。
- 原版小部件图标为独立 drawable；卡片图标复用快捷方式风格
  SVG（note+折角 / 红色录音版）—— 图标语义等价。

## 验证

- `d05-original-widget-action-cards.mjs`：24 断言全绿（5 provider
  manifest/XML/标签/extra 证据 + 声明/卡片/ingress/drain/字符串 +
  数据小部件 fail-closed 注释登记）。
- `d05-original-launcher-shortcuts.mjs` 连带更新
  （createAndLaunch 签名 pin）后 26/26 绿。
- 全量 Desktop Replay 550/550。
- `note@default` + `note@ohosTest` 双 HAP 0 错误；卡片经
  `debug_widget` 编译通道打包。
- 未启动模拟器/真机/Hypium。
