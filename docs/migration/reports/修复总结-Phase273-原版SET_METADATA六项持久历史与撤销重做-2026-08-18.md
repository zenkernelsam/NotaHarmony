# 修复总结：Phase 273 原版 SET_METADATA 六项持久历史与撤销重做

## 1. 基线与纪律

- 唯一可写工程：`C:\HarmonyProject\NotaHarmony`；会话默认 cwd 虽仍指向 Desktop，但所有开发、验证和 Git
  命令均显式使用正式仓 workdir。
- 阶段基线 `HEAD=689f0b451c8c4d8289bf704a2bc850c1acdc8cfc`，`origin/main=6f5201105e4fc994e2deeac6d4e3cb6c8833e488`；
  Phase 264～266 三个提交已再次确认完整位于 `c1be5f0`，且 `c1be5f0` 是当前 HEAD 祖先。
- Desktop 只读取原版 1.0.3、JADX 简化输出与临时证据；没有新建或维护 Harmony 源码工作树。
- 既有 `.codex-tmp-*`、`.hvigor-user-phase270/271/272`、`Chat History/`、`note/oh-package-lock.json5`
  均未删除、未提交；本阶段未 push。
- 未启动模拟器、虚拟机、真机或 Hypium。

## 2. 原版结论

直读 `.codex-tmp-phase273-vnf-simple.java`、`u5j/xj2/dhh/er6/m09/a79` 后确认：

1. 原版撤销 `SET_METADATA` 时按旧 operation 的 field presence 确定 touched register；
2. 对 touched 字段读取 NoteImpl 当前值，再经 `u5j.H → xj2.d` 编码一条新的逆向 operation；
3. 普通五项的 Java null 表示 omitted，不能删除 winner；handwriting wrapper 才能表达 explicit null；
4. 六项 register 初始可以缺席，不能为 Undo 猜造 PAGELESS、align、字体、wrap 或语言默认值。

完整 hash、行号与 Harmony 映射见
`docs/migration/evidence/original-set-metadata-history-jadx-2026-08-18.md`。

## 3. 实现内容

### 3.1 NMD1 durable companion

新增 `NoteMetadataMutationCodec.ets`：

- 固定六位 touched mask 与 NMD1 magic；
- 保存 selected page、单步 revision、before/after；
- handwriting touched null 合法，普通 touched null 拒绝；
- 未 touched 字段必须为 null；
- JSON 必须是精确六字段 object，额外/缺失/错类型/trailing bytes 全部拒绝；
- before/after 必须能重新通过生产 original writer，避免超长或坏 UTF-8 state 形成不可执行历史。

`OpType.UPDATE_NOTE_METADATA=35`、`UndoableActionType.NOTE_METADATA=23` 与容量估算形成稳定 runtime 类型。

### 3.2 原子 PUSH/UNDO/REDO

`OriginalNoteMetadataPersistence` 现可在同一 transaction 中写：

1. uploadable 原版 `ORIGINAL_SET_METADATA`；
2. local-only NMD1 history companion。

history/page/source/reversibility 均在 original identity 分配前验证。无 history 的首次普通 winner 写入允许成功；
请求 history 而旧 winner 缺席则整次失败。Undo/Redo 必须携带 expected touched source，当前值不匹配时不改
winner、revision 或 operation log。每次 Undo/Redo 都分配新的、更晚的 original operation identity。

### 3.3 持久历史恢复与编辑器路由

`PersistentHistory` 只 materialize 单一 metadata companion；多 companion action fail closed。
`UndoRedoManager` 保存 mask 与 before/after；`NoteCanvasView` 将其识别为 page action；`NotePage` 复用共享 codec
校验并调用 repository 完成 source-checked Undo/Redo。

当前没有证据支持的 PAGELESS、align-to-lines、default-font inheritance、handwriting provider 或 block-wrap UI
consumer 没有被猜造。本阶段闭环的是 durable history 基础设施与执行路径。

## 4. 边修边补审发现

第一版历史 state 只校验原版值域。补审发现 handwriting 只检查 ISO language prefix，因此一个超出 Harmony
本地 writer 1024-byte 上限的既有 winner 可能被写入 companion，却直到 Undo 才失败。现把生产 original writer
re-encodability 提升为 state 前置门禁，并新增超长 language 与 malformed UTF-8 family fixture；不可恢复动作在
operation identity 分配前拒绝。

同时保留了另一项已修正回归：无 history 的首次普通 metadata 写入不会无条件构造 before-history，因此旧 winner
缺席时仍可正常建立第一个 winner；只有承诺可撤销的 history 请求才要求可表达的 before state。

## 5. Fixture、证据与 Replay

- `note/src/test/NoteMetadataMutationCodec.test.ets`：六字段 round-trip、subset mask、explicit null、false/0、
  absent ordinary、非法值、恶意 JSON、trailing bytes、wire-reencodability。
- `note/src/test/PersistentHistory.test.ets`：metadata materialization、durable PUSH→UNDO→REDO、多 companion 拒绝。
- `docs/migration/replays/d02-original-set-metadata-history.mjs`：原版静态证据门、生产源码门与独立 SQLite
  transaction/history 模型。
- ADR：`docs/migration/adr/ADR-0251-original-set-metadata-history.md`。

## 6. 验证结果

| 门禁 | 结果 |
|---|---|
| Phase 273 专项 Replay | `D02_ORIGINAL_SET_METADATA_HISTORY_OK TOTAL=32 FAILED=0` |
| metadata/history 相关 Replay | `RELATED_REPLAY_FILES=11 PASSED=11 FAILED=0` |
| 全量 Desktop Replay | `REPLAY_FILES=258 PASSED=258 FAILED=0` |
| 增量 `note@ohosTest` | `BUILD SUCCESSFUL in 6 s 859 ms` |
| `git diff --check` | 通过（仅 Windows 换行转换提示） |
| clean | `BUILD SUCCESSFUL in 2 s 12 ms` |
| clean 后 `note@ohosTest` | `BUILD SUCCESSFUL in 7 s 539 ms` |
| clean 后 `note@default` | `BUILD SUCCESSFUL in 59 s 893 ms` |

default 构建只有项目既有 ArkTS exception/deprecation 与 unsigned-signing warning；未执行设备测试或 Hypium。

## 7. 阶段边界与后续

本阶段闭环六项 metadata 的 local original operation、durable companion、重启 materialization 与 source-checked
Undo/Redo 基础设施。仍不能宣称：

- PAGELESS/align/handwriting/default-font/block-wrap consumer 或设置 UI；
- 真实旧库升级、多设备/服务端同步、NOTE_BUNDLE round-trip；
- 设备上的撤销手感、像素、性能与错误提示。

这些继续保留为后续原版证据或设备验收项。`T-042` APK 版本追踪仍严格留到整个 Goal 最后一项。
