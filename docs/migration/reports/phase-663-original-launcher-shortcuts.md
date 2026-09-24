# Phase 663：原版桌面快捷方式（v50 new_note/new_photo → 建笔记直开）

日期：2026-09-24
接续：Phase 662（导入详情页）

## 原版依据

- `v50`：`ShortcutManager` 动态发布 `new_note`（CREATE_NOTE intent）
  与 `new_photo`（同 intent + `start_camera` extra，`pceVar` 门控），
  及最近笔记动态快捷项（`fad.R` setDynamicShortcuts）。
- `hv7.i`：CREATE_NOTE → `Q.j=true` + `kx` 协程建笔记直开。
- 详见 `docs/migration/evidence/phase-663-original-launcher-shortcuts.md`
  与 ADR-0630。

## Harmony 实现

- `module.json5` → `NoteAbility.metadata`:
  `ohos.ability.shortcuts` → `$profile:shortcuts_config`。
- `shortcuts_config.json`：`new_note`/`new_photo` 静态快捷项，
  want `parameters.launch_action` = `create_note`/`create_photo_note`；
  新 SVG 图标两枚 + base/zh_CN 字符串。
- `data/LaunchActionIngress.ets`（新）：`enqueueLaunchAction` 白名单
  读参 + `drainLaunchActions` 原子清空（与 SharedFileIngress 同构）。
- `NoteAbility.onCreate/onNewWant`：入队（与共享 URI 队列并列）。
- `LibraryPage.onPageShow` → `drainLaunchIngress` →
  `createAndLaunch`（第三参 `startCamera`）→ pushUrl
  `startCamera:'1'`。
- `NotePage`：`startCamera` param → `autoCameraRequested` → 载入完成
  后 `photoImportLeaseActive = true; cameraCaptureSignal++`（与
  Take Photo 同一 ingress lease；pageLoadGeneration + editorDisposed
  守卫同 autoRecord 挂点）。

## fail-closed 登记

- 最近笔记动态快捷项：`setDynamicShortcuts` 无 Harmony 对应 API ——
  静态声明制下不实现（LaunchActionIngress 注释登记）。
- `new_photo` 的 `pceVar` 门控不复制（权限由拍摄 ingress 处理）。

## 验证

- `d05-original-launcher-shortcuts.mjs`：26 断言。
- 全量 Desktop Replay：548/548。
- `note@default` HAP 构建绿；clean + `note@ohosTest` 见提交记录。

## 文件清单

- `note/src/main/module.json5`
- `note/src/main/resources/base/profile/shortcuts_config.json`（新）
- `note/src/main/resources/base/media/shortcut_new_note.svg`（新）
- `note/src/main/resources/base/media/shortcut_new_photo.svg`（新）
- `note/src/main/ets/data/LaunchActionIngress.ets`（新）
- `note/src/main/ets/noteability/NoteAbility.ets`
- `note/src/main/ets/ui/library/LibraryPage.ets`
- `note/src/main/ets/ui/editor/NotePage.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/replays/d05-original-launcher-shortcuts.mjs`（新）
- `docs/migration/evidence/phase-663-original-launcher-shortcuts.md`（新）
- `docs/migration/adr/ADR-0630-original-launcher-shortcuts.md`（新）
