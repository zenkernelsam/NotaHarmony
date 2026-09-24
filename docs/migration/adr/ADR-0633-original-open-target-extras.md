# ADR-0633：原版打开目标 extras（note_id / nbnote / show_library / show_recent）

- 状态：已接受
- 日期：2026-09-24
- 关联：Phase 666；前置 ADR-0631（深链）、ADR-0632（动作卡片）；
  证据 `evidence/phase-666-original-open-target-extras.md`；
  Replay `d05-original-open-target-extras.mjs`

## 背景

原版所有"打开指定笔记/落地资料库"的内部入口共用同一 VIEW
intent extra 契约：`note_id`（`ttf.toString()` 8-4-4-4-12 带
连字符 UUID；`m18.r0` 兼容 32-hex 与 36 位带连字符）、
`nbnote:<id>` data URI（qk9 小部件行 fillInIntent）、
`show_library`/`show_recent` 布尔。投递方包括 v50 近期笔记动态
快捷项、qk9 小部件行、bv7 新窗口目标、RecentNotes 小部件本体。
MainActivity 把它们归一为 nav-target 队列（`xu7`/`wu7.a`）。

## 决策

1. `DeepLinkIngress` 的 ID 校验升级为
   `normalizeDeepLinkNoteId`：同时接受 `m18.r0` 的两种形式
   （32-hex 与 8-4-4-4-12 带连字符，连字符校验 8/13/18/23），
   统一输出小写 32-hex —— 与导入笔记的入库 ID 形式一致。
   `/app/note` 深链路径段同样获益（原版 `py2.b` 也走 `r0`）。
2. 新增 `OpenTargetIngress.ets`（与既有 ingress 同构）：
   `want.parameters['note_id']` 与 `want.uri` 的 `nbnote:` 前缀
   归一化入 `pendingOpenNoteIds`；`show_library`/`show_recent`
   布尔入 `pendingLandings`（`all_notes`/`recent`）。
3. `NoteAbility.onCreate/onNewWant` 增挂 `enqueueOpenTargetWant`。
4. `LibraryPage.drainDeepLinkIngress` 合并两条笔记 ID 队列
   （深链 + 打开目标）→ 同一 `resolveDeepLinkNoteId` +
   `pushUrl NotePage` 管线；新增 `drainOpenTargetIngress`：
   最后一个落地请求生效，`recent` → `LibrarySection.RECENT`，
   否则 `ALL_NOTES`。
5. `nbnote` 不注册 uris skill —— 原版 manifest 同样未声明，
   属内部 URI；仅 want.uri 实际到达时解析。

## 差异登记（fail-closed）

- `show_recent` 的原版精确 nav 目标 opaque —— 映射为 RECENT
  区段（最贴近表达）；`show_library` → ALL_NOTES（资料库根）。
- 未命中笔记沿用深链 `deep_link_note_missing` toast；后端同步
  取回属订阅域 fail-closed。

## 验证

- `d05-original-open-target-extras.mjs`：23 断言全绿（5 类投递方
  extras/URI 证据 + ttf/m18 双形式证据 + ingress/管线/区段/未声明
  nbnote + 回归保护）。
- `d05-original-note-deep-link.mjs` 连带更新（双形式 validator
  pins）后 31/31 绿。
- 全量 Desktop Replay 551/551。
- `note@default` + `note@ohosTest` 双 HAP 0 错误。
- 未启动模拟器/真机/Hypium。
