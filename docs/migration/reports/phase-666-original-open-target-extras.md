# Phase 666：原版打开目标 extras（note_id / nbnote / show_library / show_recent）

日期：2026-09-24
接续：Phase 665（动作小部件卡片）

## 原版依据

- 统一 VIEW+extras 打开目标契约，投递方四处：
  `v50` 近期笔记动态快捷项（`putExtra("note_id", ttf.toString())`）、
  `qk9` 小部件行（`data=nbnote:<ttf>` + `note_id`）、`bv7` 新窗口
  目标（`note_id` + flags）、RecentNotes 本体（`show_recent`）。
- `MainActivity:467` 消费 `note_id`/`show_library` → nav-target
  `xu7(noteId)`/`wu7.a`。
- `ttf.toString()` = 8-4-4-4-12 带连字符 UUID；`m18.r0` 兼容
  32-hex 与 36 位带连字符两种文本形式。
- `nbnote` 未在 manifest 声明 —— 内部 URI。
- 详见 `docs/migration/evidence/phase-666-original-open-target-extras.md`
  与 ADR-0633。

## Harmony 实现

- `DeepLinkIngress`：`isDeepLinkNoteId` 升级为导出
  `normalizeDeepLinkNoteId` —— 接受 32-hex 或 8-4-4-4-12
  （连字符校验 8/13/18/23），统一输出小写 32-hex（入库 ID
  形式）；`/app/note` 深链路径同步获益（原版 `py2.b`→`r0`
  同双形式）。
- 新 `OpenTargetIngress.ets`：`note_id` extra 与 `nbnote:` URI
  → 归一化入 `pendingOpenNoteIds`；`show_library`/`show_recent`
  布尔 → `pendingLandings`（`all_notes`/`recent`）。
- `NoteAbility.onCreate/onNewWant`：`enqueueOpenTargetWant`。
- `LibraryPage`：`drainDeepLinkIngress` 合并两条笔记 ID 队列
  → 同一 `resolveDeepLinkNoteId` + `pushUrl`；新增
  `drainOpenTargetIngress` → 末位落地请求 `selectSection`
  （recent→RECENT，library→ALL_NOTES）。

## fail-closed 登记

- `nbnote` 不声明 uris skill（原版亦内部 URI）。
- `show_recent` 精确 nav 语义 opaque → RECENT 区段映射。
- 未命中笔记沿用 `deep_link_note_missing` toast（后端取回
  订阅域）。

## 验证

- `d05-original-open-target-extras.mjs`：23 断言全绿。
- 连带更新 `d05-original-note-deep-link.mjs`（双形式 validator
  pins）31/31 绿。
- 全量 Desktop Replay 551/551。
- `note@default` + `note@ohosTest` 双 HAP 0 错误。
- 未启动模拟器/真机/Hypium。
