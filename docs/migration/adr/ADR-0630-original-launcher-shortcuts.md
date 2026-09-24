# ADR-0630 原版桌面快捷方式（v50 new_note/new_photo → 建笔记直开）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：663
- 接续：ADR-0628（共享 want 队列模式）、ADR-0624（编辑器拍摄入口）
- 证据：`docs/migration/evidence/phase-663-original-launcher-shortcuts.md`

## 背景

原版 `v50` 通过 `ShortcutManager.setDynamicShortcuts` 发布桌面长按
快捷项：`new_note`（CREATE_NOTE intent）与 `new_photo`（同 intent +
`start_camera` extra，受 `pceVar` 门控），外加由最近笔记驱动的
动态快捷项。`hv7.i` 对 CREATE_NOTE 置 `Q.j` 启动标记后走 `kx`
协程建笔记直开；`start_camera` 使编辑器直起拍摄。

Harmony 侧此前无快捷方式声明 —— 真实缺口。

## 决定

1. **静态快捷声明**：`ohos.ability.shortcuts` metadata →
   `shortcuts_config.json`，`new_note`/`new_photo` 两项，
   `wants[].parameters.launch_action` = `create_note` /
   `create_photo_note`。
2. **队列模式复用**：`LaunchActionIngress`（与 SharedFileIngress
   同构）白名单读参入队；`NoteAbility.onCreate/onNewWant` 入队；
   `LibraryPage.onPageShow` drain。
3. **消费管线复用**：drain → `createAndLaunch`（与内建「+」同一
   管线），`create_photo_note` → `startCamera:'1'` page param →
   `NotePage` 载入后 `photoImportLeaseActive + cameraCaptureSignal`
   直起拍摄（与 Take Photo 同一 ingress lease）。
4. **fail-closed**：原版最近笔记动态快捷项无 Harmony 对应 API
   （`ohos.ability.shortcuts` 静态声明制），登记不实现；
   `new_photo` 的 `pceVar` 门控不复制（权限留给拍摄 ingress 处理）。

## 差异

- 快捷项为静态两项；动态近期笔记入口由库页承担。
- 快捷图标为按原版语义重绘的单色 SVG（非原版 adaptive-icon 位图）。

## 验证

- `d05-original-launcher-shortcuts.mjs`：26 断言。
- 全量套件与双 HAP 见 Phase 663 report。
